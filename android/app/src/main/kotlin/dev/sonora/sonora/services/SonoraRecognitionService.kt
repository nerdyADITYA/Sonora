package dev.sonora.sonora.services

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import dev.sonora.sonora.audio.AudioCaptureException
import dev.sonora.sonora.audio.AudioCaptureManager
import dev.sonora.sonora.audio.AudioConfiguration
import dev.sonora.sonora.audio.GatedCapture
import dev.sonora.sonora.database.HistoryRepository
import dev.sonora.sonora.database.RecognitionSource
import dev.sonora.sonora.notifications.RecognitionNotificationManager
import dev.sonora.sonora.recognition.ArtworkResolver
import dev.sonora.sonora.recognition.Connectivity
import dev.sonora.sonora.spotify.SpotifyManager
import dev.sonora.sonora.recognition.MatchSelector
import dev.sonora.sonora.recognition.RecognitionEngine
import dev.sonora.sonora.recognition.RecognitionEngineFactory
import dev.sonora.sonora.recognition.RecognitionErrorCodes
import dev.sonora.sonora.recognition.RecognitionOutcome
import dev.sonora.sonora.recognition.RecognizedSong

/**
 * User-started ambient listening, as a microphone foreground service.
 *
 * Each cycle opens the microphone for a 3 s loudness probe and, if it is
 * loud enough, continues to a 10 s sample that is fingerprinted and matched.
 * Between cycles the microphone is closed. Audio exists only in memory and is
 * wiped after each cycle.
 *
 * The service is START_NOT_STICKY: Android doesn't allow restarting
 * microphone capture from the background, so after process death the user
 * starts listening again.
 */
class SonoraRecognitionService : Service() {

    private lateinit var audio: AudioCaptureManager
    private lateinit var engine: RecognitionEngine
    private lateinit var budget: RequestBudget
    private lateinit var history: HistoryRepository
    private lateinit var notifications: RecognitionNotificationManager
    private lateinit var workerThread: HandlerThread
    private lateinit var worker: Handler
    private var wakeLock: PowerManager.WakeLock? = null

    @Volatile
    private var running = false
    private var consecutiveNoMatches = 0

    /** A 50–69 score match waiting for a second sample to agree, and when it was heard. */
    private var unconfirmed: Pair<RecognizedSong, Long>? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        audio = AudioCaptureManager(this)
        engine = RecognitionEngineFactory.create(this)
        budget = RequestBudget(this)
        history = HistoryRepository.get(this)
        notifications = RecognitionNotificationManager(this)
        workerThread = HandlerThread("sonora-listening").also { it.start() }
        worker = Handler(workerThread.looper)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopListening()
        } else {
            startListening()
        }
        return START_NOT_STICKY
    }

    private fun startListening() {
        if (running) {
            // Every startForegroundService() call must be answered with startForeground().
            enterForeground()
            return
        }
        if (!audio.hasPermission()) {
            fail(AudioCaptureManager.PERMISSION_REQUIRED)
            return
        }

        ServiceStateManager.update {
            it.copy(
                phase = ListeningPhase.WAITING,
                requestsToday = budget.usedToday(),
                dailyBudget = budget.limit,
                lastError = null,
            )
        }
        try {
            enterForeground()
        } catch (e: Exception) {
            // ForegroundServiceStartNotAllowedException / SecurityException: started from the background.
            Log.e(TAG, "Could not start the microphone foreground service", e)
            fail(FOREGROUND_NOT_ALLOWED)
            return
        }

        running = true
        consecutiveNoMatches = 0
        acquireWakeLock()
        worker.post(::runCycle)
    }

    private fun enterForeground() {
        val notification = notifications.build(ServiceStateManager.snapshot)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                RecognitionNotificationManager.NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
            )
        } else {
            startForeground(RecognitionNotificationManager.NOTIFICATION_ID, notification)
        }
    }

    private fun stopListening() {
        running = false
        audio.cancel()
        worker.removeCallbacksAndMessages(null)
        releaseWakeLock()
        ServiceStateManager.update { it.copy(phase = ListeningPhase.STOPPED, nextCheckAt = null) }
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun fail(code: String) {
        running = false
        ServiceStateManager.update { it.copy(phase = ListeningPhase.STOPPED, nextCheckAt = null, lastError = code) }
        stopSelf()
    }

    /** One probe/capture/match cycle. Runs on the worker thread and schedules the next. */
    private fun runCycle() {
        if (!running) return

        if (!budget.hasRemaining()) {
            schedule(BUDGET_RECHECK_MS, ListeningPhase.PAUSED_BUDGET)
            return
        }

        // Online only: don't open the microphone or spend a request without a connection.
        if (!Connectivity.isOnline(this)) {
            schedule(ListeningPolicy.OFFLINE_RECHECK_MS, ListeningPhase.OFFLINE)
            return
        }

        setPhase(ListeningPhase.LISTENING)
        if (!running) return
        val capture = try {
            audio.captureGated(ListeningPolicy.PROBE_MS, ListeningPolicy.CAPTURE_MS, ListeningPolicy.MIN_LEVEL_DBFS)
        } catch (e: AudioCaptureException) {
            when (e.code) {
                AudioCaptureManager.CANCELLED -> return // Stopping.
                AudioCaptureManager.PERMISSION_REQUIRED -> {
                    mainThread { fail(e.code) }
                    return
                }
                else -> {
                    schedule(ListeningPolicy.ERROR_DELAY_MS, ListeningPhase.MICROPHONE_BLOCKED, e.code)
                    return
                }
            }
        }

        when (capture) {
            GatedCapture.Silent -> schedule(ListeningPolicy.SILENT_DELAY_MS, ListeningPhase.MICROPHONE_BLOCKED)
            is GatedCapture.TooQuiet -> schedule(ListeningPolicy.QUIET_DELAY_MS)
            is GatedCapture.Captured -> recognise(capture.pcm)
        }
    }

    private fun recognise(pcm: ByteArray) {
        setPhase(ListeningPhase.MATCHING)
        budget.record()
        val outcome = try {
            engine.recognize(pcm, AudioConfiguration.SAMPLE_RATE_HZ, AudioConfiguration.CHANNEL_COUNT)
        } finally {
            pcm.fill(0)
        }
        if (!running) return

        when (outcome) {
            is RecognitionOutcome.Match -> {
                consecutiveNoMatches = 0
                val song = outcome.song
                val now = System.currentTimeMillis()
                val pending = unconfirmed?.takeIf { now - it.second < ListeningPolicy.CONFIRM_WINDOW_MS }?.first
                when {
                    // Confident, or a second sample agreeing with an earlier uncertain one.
                    outcome.confident || (pending != null && MatchSelector.confirms(pending, song)) -> {
                        unconfirmed = null
                        saveAndAnnounce(song)
                        schedule(ListeningPolicy.delayAfterMatch(song.durationMs, song.playOffsetMs))
                    }
                    // Uncertain: hold it and listen again soon instead of saving a possible wrong song.
                    else -> {
                        unconfirmed = song to now
                        schedule(ListeningPolicy.CONFIRM_DELAY_MS)
                    }
                }
            }
            RecognitionOutcome.NoMatch -> {
                consecutiveNoMatches++
                schedule(ListeningPolicy.delayAfterNoMatch(consecutiveNoMatches))
            }
            is RecognitionOutcome.Failure -> when (outcome.code) {
                // Retrying can't fix these; stop rather than burn battery.
                RecognitionErrorCodes.INVALID_CREDENTIALS,
                RecognitionErrorCodes.NOT_CONFIGURED,
                RecognitionErrorCodes.PROVIDER_UNAVAILABLE -> mainThread {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    releaseWakeLock()
                    fail(outcome.code)
                }
                else -> schedule(ListeningPolicy.ERROR_DELAY_MS, ListeningPhase.WAITING, outcome.code)
            }
        }
    }

    /**
     * Saves the match unless the same song was saved within the duplicate
     * window (checked in the database, so it survives restarts), then
     * announces it. Artwork is fetched only for songs that don't have it yet.
     */
    private fun saveAndAnnounce(heard: RecognizedSong) {
        // Spotify's usual version first, so the cover matches what the Spotify app shows.
        val song = SpotifyManager.get(this).preferredVersion(heard)
        val recorded = try {
            history.record(song, RecognitionSource.AMBIENT, ListeningPolicy.DUPLICATE_WINDOW_MS)
        } catch (e: Exception) {
            Log.e(TAG, "Could not save recognition", e)
            null
        }
        if (recorded?.duplicate == true) return

        val withArtwork = recorded?.storedArtworkUrl?.let { song.copy(artworkUrl = it) }
            ?: ArtworkResolver.enrich(song).also { enriched ->
                val url = enriched.artworkUrl
                if (recorded != null && url != null) {
                    runCatching { history.updateArtwork(recorded.songId, url) }
                }
            }
        ServiceStateManager.announceSong(withArtwork)
    }

    private fun schedule(delayMs: Long, phase: ListeningPhase = ListeningPhase.WAITING, error: String? = null) {
        if (!running) return
        ServiceStateManager.update {
            it.copy(
                phase = phase,
                nextCheckAt = System.currentTimeMillis() + delayMs,
                requestsToday = budget.usedToday(),
                lastError = error,
            )
        }
        notifications.update(ServiceStateManager.snapshot)
        worker.postDelayed(::runCycle, delayMs)
    }

    private fun setPhase(phase: ListeningPhase) {
        ServiceStateManager.update { it.copy(phase = phase, nextCheckAt = null) }
        notifications.update(ServiceStateManager.snapshot)
    }

    private fun mainThread(block: () -> Unit) = Handler(mainLooper).post(block)

    /**
     * Keeps the CPU running so scheduled checks happen with the screen off.
     * This is the main battery cost of listening and is measured in Phase 7.
     */
    private fun acquireWakeLock() {
        val power = getSystemService(PowerManager::class.java)
        wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Sonora:listening").apply {
            setReferenceCounted(false)
            acquire(WAKE_LOCK_TIMEOUT_MS)
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.takeIf { it.isHeld }?.release()
        wakeLock = null
    }

    override fun onDestroy() {
        if (running) {
            running = false
            audio.cancel()
            ServiceStateManager.update { it.copy(phase = ListeningPhase.STOPPED, nextCheckAt = null) }
        }
        releaseWakeLock()
        worker.removeCallbacksAndMessages(null)
        worker.post { engine.release() }
        workerThread.quitSafely()
        super.onDestroy()
    }

    companion object {
        private const val TAG = "SonoraListening"
        private const val ACTION_START = "dev.sonora.sonora.action.START_LISTENING"
        private const val ACTION_STOP = "dev.sonora.sonora.action.STOP_LISTENING"
        private const val BUDGET_RECHECK_MS = 30 * 60_000L
        private const val WAKE_LOCK_TIMEOUT_MS = 12 * 60 * 60_000L

        const val FOREGROUND_NOT_ALLOWED = "FOREGROUND_NOT_ALLOWED"

        fun startIntent(context: Context) =
            Intent(context, SonoraRecognitionService::class.java).setAction(ACTION_START)

        fun stopIntent(context: Context) =
            Intent(context, SonoraRecognitionService::class.java).setAction(ACTION_STOP)

        /** Must be called while the app is visible: Android requires it for microphone services. */
        fun start(context: Context) {
            val intent = startIntent(context)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.startService(stopIntent(context))
        }
    }
}
