package dev.sonora.sonora.recognition

import dev.sonora.sonora.spotify.SpotifyManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import dev.sonora.sonora.audio.AudioCaptureException
import dev.sonora.sonora.audio.AudioCaptureManager
import dev.sonora.sonora.audio.AudioConfiguration
import dev.sonora.sonora.bridge.BridgeContract
import dev.sonora.sonora.bridge.SonoraEvents
import dev.sonora.sonora.database.HistoryRepository
import dev.sonora.sonora.database.RecognitionSource
import dev.sonora.sonora.services.ServiceStateManager
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Coordinates one capture-then-match cycle. Independent of Flutter: results go
 * to the callback and, as events, through [SonoraEvents].
 *
 * Phase 2 supports manual one-shot recognition only. Continuous listening
 * (Phase 3) will drive this from a foreground service.
 */
class RecognitionManager(context: Context) {

    private val appContext = context.applicationContext
    private val audio = AudioCaptureManager(appContext)
    private val engine: RecognitionEngine by lazy { RecognitionEngineFactory.create(appContext) }
    private val worker = Executors.newSingleThreadExecutor { Thread(it, "sonora-recognition") }
    private val mainHandler = Handler(Looper.getMainLooper())
    private val busy = AtomicBoolean(false)
    private val history = HistoryRepository.get(appContext)

    val hasMicrophonePermission: Boolean get() = audio.hasPermission()

    val isBusy: Boolean get() = busy.get()

    /** [onComplete] runs on the main thread with the outcome and the elapsed milliseconds. */
    fun recognizeOnce(onComplete: (RecognitionOutcome, Long) -> Unit) {
        if (ServiceStateManager.snapshot.listening) {
            onComplete(
                RecognitionOutcome.Failure(
                    RecognitionErrorCodes.LISTENING_ACTIVE,
                    "Ambient listening is on and already using the microphone.",
                ),
                0,
            )
            return
        }
        if (!busy.compareAndSet(false, true)) {
            onComplete(RecognitionOutcome.Failure(RecognitionErrorCodes.BUSY, "Recognition already running."), 0)
            return
        }

        worker.execute {
            val started = SystemClock.elapsedRealtime()
            val outcome = try {
                SonoraEvents.emit(BridgeContract.Events.RECOGNITION_CAPTURING)
                val pcm = audio.capture()
                try {
                    SonoraEvents.emit(BridgeContract.Events.RECOGNITION_MATCHING)
                    engine.recognize(pcm, AudioConfiguration.SAMPLE_RATE_HZ, AudioConfiguration.CHANNEL_COUNT)
                } finally {
                    pcm.fill(0) // Raw audio is never persisted; wipe the only copy.
                }
            } catch (e: AudioCaptureException) {
                RecognitionOutcome.Failure(e.code, e.message ?: "Microphone error.")
            } catch (e: Exception) {
                RecognitionOutcome.Failure(RecognitionErrorCodes.PROVIDER_ERROR, "Recognition failed.")
            }
            // Measured before the artwork lookup so it reflects recognition latency only.
            val elapsed = SystemClock.elapsedRealtime() - started
            val enriched = if (outcome is RecognitionOutcome.Match) withArtwork(outcome) else outcome
            busy.set(false)
            mainHandler.post { onComplete(enriched, elapsed) }
        }
    }

    /** Adds artwork and saves the match to history (manual matches are never suppressed). */
    private fun withArtwork(match: RecognitionOutcome.Match): RecognitionOutcome.Match {
        // Spotify's usual version first, so the cover matches what the Spotify app shows.
        val song = ArtworkResolver.enrich(SpotifyManager.get(appContext).preferredVersion(match.song))
        try {
            history.record(song, RecognitionSource.MANUAL)
        } catch (e: Exception) {
            Log.e(TAG, "Could not save recognition", e)
        }
        return RecognitionOutcome.Match(song, match.confident)
    }

    fun cancel() = audio.cancel()

    private companion object {
        const val TAG = "RecognitionManager"
    }

    fun release() {
        audio.cancel()
        worker.execute { engine.release() }
        worker.shutdown()
    }
}
