package dev.sonora.sonora.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.widget.Toast
import dev.sonora.sonora.services.ServiceStateManager
import dev.sonora.sonora.spotify.SpotifyException
import dev.sonora.sonora.spotify.SpotifyManager

/**
 * The notification's "Save to <playlist>" action: adds the last song to the
 * default Spotify playlist, through the same queue as the app (never twice).
 */
class SaveToPlaylistReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val songId = intent.getLongExtra(EXTRA_SONG_ID, -1)
        if (songId < 0) return
        val appContext = context.applicationContext
        val pending = goAsync()
        Thread {
            try {
                val spotify = SpotifyManager.get(appContext)
                val (playlistId, name) = spotify.defaultPlaylist()
                    ?: return@Thread toast(appContext, "Choose a playlist in Sonora first.")
                val result = spotify.addSong(songId, playlistId, name, null)
                ServiceStateManager.update { if (it.lastSongId == songId) it.copy(savedTo = name) else it }
                toast(appContext, if (result == SpotifyManager.AddResult.ADDED) "Added to $name" else "Already in $name")
            } catch (e: SpotifyException) {
                toast(appContext, e.message ?: "Couldn't add to Spotify.")
            } finally {
                pending.finish()
            }
        }.start()
    }

    private fun toast(context: Context, text: String) {
        Handler(Looper.getMainLooper()).post { Toast.makeText(context, text, Toast.LENGTH_SHORT).show() }
    }

    companion object {
        const val EXTRA_SONG_ID = "dev.sonora.sonora.extra.SONG_ID"
    }
}
