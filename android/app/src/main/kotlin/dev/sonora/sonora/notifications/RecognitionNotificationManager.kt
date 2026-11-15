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
import dev.sonora.sonora.recognition.SpotifyLinks
import dev.sonora.sonora.services.ServiceStateManager
import dev.sonora.sonora.services.SonoraRecognitionService
import dev.sonora.sonora.services.statusText
import dev.sonora.sonora.spotify.SpotifyManager
import java.net.HttpURLConnection
import java.net.URL

/**
 * The single, silent, ongoing listening notification. It shows status or the
 * last recognised song, with Stop and, when possible, Save to the default
 * Spotify playlist and Open in Spotify. Tapping a song opens it in Sonora.
 * The lock screen shows only "Sonora is listening".
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
        val status = state.statusText()

        val builder = newBuilder()
            .setSmallIcon(R.drawable.ic_stat_sonora)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setContentIntent(openAppIntent(state.lastSongId))
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setPublicVersion(publicVersion())
            .addAction(Notification.Action.Builder(null, "Stop", stopIntent()).build())

        if (song == null) {
            builder.setContentTitle("Sonora is listening").setContentText(status)
        } else {
            builder
                .setContentTitle(song.title)
                .setContentText(song.artist)
                .setSubText(state.savedTo?.let { "Saved to $it" } ?: status)
                .setLargeIcon(artworkFor(song.artworkUrl))
            val playlist = if (state.savedTo == null) SpotifyManager.get(context).defaultPlaylist() else null
            if (song.spotifyTrackId != null && state.lastSongId != null && playlist != null) {
                builder.addAction(
                    Notification.Action.Builder(null, "Save to ${playlist.second}", saveIntent(state.lastSongId)).build(),
                )
            }
            // Shown only for songs matched to Spotify, so the search finds it.
            if (song.spotifyTrackId != null) {
                builder.addAction(
                    Notification.Action.Builder(null, "Open in Spotify", spotifyIntent(song.title, song.artist)).build(),
                )
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

    /** Opens the app, on the song's page when there is one. */
    private fun openAppIntent(songId: Long?): PendingIntent = PendingIntent.getActivity(
        context,
        0,
        Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .apply { songId?.let { putExtra(MainActivity.EXTRA_SONG_ID, it) } },
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private fun saveIntent(songId: Long): PendingIntent = PendingIntent.getBroadcast(
        context,
        3,
        Intent(context, SaveToPlaylistReceiver::class.java).putExtra(SaveToPlaylistReceiver.EXTRA_SONG_ID, songId),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private fun stopIntent(): PendingIntent = PendingIntent.getService(
        context,
        1,
        SonoraRecognitionService.stopIntent(context),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private fun spotifyIntent(title: String, artist: String): PendingIntent = PendingIntent.getActivity(
        context,
        2,
        Intent(Intent.ACTION_VIEW, Uri.parse(SpotifyLinks.view(title, artist)))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    companion object {
        private const val TAG = "SonoraNotifications"
        const val CHANNEL_ID = "sonora_listening"
        const val NOTIFICATION_ID = 1001
    }
}
