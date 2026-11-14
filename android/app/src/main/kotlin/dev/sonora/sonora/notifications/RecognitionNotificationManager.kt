package dev.sonora.sonora.notifications

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.util.Log
import dev.sonora.sonora.MainActivity
import dev.sonora.sonora.R
import dev.sonora.sonora.services.ListeningPhase
import dev.sonora.sonora.services.ServiceStateManager
import dev.sonora.sonora.services.SonoraRecognitionService
import java.net.HttpURLConnection
import java.net.URL

/**
 * The single, silent, ongoing listening notification. It shows status or the
 * last recognised song, with Stop and (when known) Open in Spotify actions.
 */
class RecognitionNotificationManager(private val context: Context) {

    private val manager = context.getSystemService(NotificationManager::class.java)
    private var artworkUrl: String? = null
    private var artwork: Bitmap? = null

    init {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "Ambient listening", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Shown while Sonora is listening, with the last song it recognised."
                setShowBadge(false)
            }
            manager.createNotificationChannel(channel)
        }
    }

    fun build(state: ServiceStateManager.Snapshot): Notification {
        val song = state.lastSong
        val status = statusText(state)

        val builder = newBuilder()
            .setSmallIcon(R.drawable.ic_stat_sonora)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setContentIntent(openAppIntent())
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setPublicVersion(publicVersion())
            .addAction(Notification.Action.Builder(null, "Stop", stopIntent()).build())

        if (song == null) {
            builder.setContentTitle("Sonora is listening").setContentText(status)
        } else {
            builder
                .setContentTitle(song.title)
                .setContentText(song.artist)
                .setSubText(status)
                .setLargeIcon(artworkFor(song.artworkUrl))
            song.spotifyTrackId?.let { id ->
                builder.addAction(Notification.Action.Builder(null, "Open in Spotify", spotifyIntent(id)).build())
            }
        }
        return builder.build()
    }

    fun update(state: ServiceStateManager.Snapshot) {
        try {
            manager.notify(NOTIFICATION_ID, build(state))
        } catch (e: SecurityException) {
            // POST_NOTIFICATIONS denied: the service keeps running; Android still lists it in the task manager.
            Log.w(TAG, "Notification not shown", e)
        }
    }

    private fun statusText(state: ServiceStateManager.Snapshot): String = when (state.phase) {
        ListeningPhase.STOPPED -> "Stopped"
        ListeningPhase.WAITING -> "Listening for music"
        ListeningPhase.LISTENING -> "Listening…"
        ListeningPhase.MATCHING -> "Identifying…"
        ListeningPhase.PAUSED_BUDGET -> "Paused: daily limit of ${state.dailyBudget} reached"
        ListeningPhase.MICROPHONE_BLOCKED -> "Microphone blocked or in use"
    }

    /** Downloads artwork once per URL. Call from a worker thread (the service's). */
    private fun artworkFor(url: String?): Bitmap? {
        if (url == null) return null
        if (url == artworkUrl) return artwork
        artworkUrl = url
        artwork = try {
            val connection = URL(url).openConnection() as HttpURLConnection
            connection.connectTimeout = 4_000
            connection.readTimeout = 4_000
            try {
                connection.inputStream.use(BitmapFactory::decodeStream)
            } finally {
                connection.disconnect()
            }
        } catch (e: Exception) {
            null
        }
        return artwork
    }

    private fun publicVersion(): Notification = newBuilder()
        .setSmallIcon(R.drawable.ic_stat_sonora)
        .setContentTitle("Sonora is listening")
        .build()

    @Suppress("DEPRECATION")
    private fun newBuilder(): Notification.Builder =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            Notification.Builder(context).setPriority(Notification.PRIORITY_LOW)
        }

    private fun openAppIntent(): PendingIntent = PendingIntent.getActivity(
        context,
        0,
        Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private fun stopIntent(): PendingIntent = PendingIntent.getService(
        context,
        1,
        SonoraRecognitionService.stopIntent(context),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private fun spotifyIntent(trackId: String): PendingIntent = PendingIntent.getActivity(
        context,
        2,
        Intent(Intent.ACTION_VIEW, Uri.parse("https://open.spotify.com/track/$trackId"))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    companion object {
        private const val TAG = "SonoraNotifications"
        const val CHANNEL_ID = "sonora_listening"
        const val NOTIFICATION_ID = 1001
    }
}
