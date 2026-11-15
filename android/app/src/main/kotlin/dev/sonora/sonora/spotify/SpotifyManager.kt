package dev.sonora.sonora.spotify

import android.content.Context
import android.net.Uri
import android.util.Log
import dev.sonora.sonora.bridge.BridgeContract
import dev.sonora.sonora.bridge.SonoraEvents
import dev.sonora.sonora.database.HistoryRepository
import dev.sonora.sonora.database.PlaylistSyncQueue
import dev.sonora.sonora.database.SyncStatus
import dev.sonora.sonora.recognition.ArtworkResolver
import dev.sonora.sonora.recognition.RecognizedSong

/**
 * Coordinates the Spotify integration: sign-in, the user's playlists, and
 * adding recognised songs through the [PlaylistSyncQueue]. Blocking methods;
 * call off the main thread. Changes emit `spotify_status`.
 */
class SpotifyManager private constructor(context: Context) {

    private val appContext = context.applicationContext
    private val auth = SpotifyAuth(appContext)
    private val api = SpotifyApi(auth)
    private val history = HistoryRepository.get(appContext)
    private val queue = PlaylistSyncQueue.get(appContext)
    private val prefs = appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    enum class AddResult(val wire: String) {
        ADDED("added"),
        ALREADY_IN_PLAYLIST("already_in_playlist"),
    }

    fun status(): Map<String, Any?> {
        val connected = auth.isSignedIn
        return mapOf(
            "configured" to auth.isConfigured,
            "connected" to connected,
            "displayName" to if (connected) prefs.getString(KEY_NAME, null) else null,
            "defaultPlaylist" to prefs.getString(KEY_PLAYLIST_ID, null)?.takeIf { connected }?.let {
                mapOf("id" to it, "name" to prefs.getString(KEY_PLAYLIST_NAME, null))
            },
        )
    }

    /** The remembered playlist as (id, name), when connected. */
    fun defaultPlaylist(): Pair<String, String>? {
        if (!auth.isSignedIn) return null
        val id = prefs.getString(KEY_PLAYLIST_ID, null) ?: return null
        return id to (prefs.getString(KEY_PLAYLIST_NAME, null) ?: "your playlist")
    }

    fun beginSignIn(): String = auth.beginSignIn()

    /** Finishes sign-in from the redirect and records who signed in. */
    fun completeSignIn(redirect: Uri) {
        try {
            auth.completeSignIn(redirect)
            val user = api.me()
            prefs.edit().putString(KEY_USER_ID, user.id).putString(KEY_NAME, user.displayName).apply()
            publish()
        } catch (e: SpotifyException) {
            Log.w(TAG, "Spotify sign-in failed: ${e.code}")
            SonoraEvents.emit(BridgeContract.Events.SPOTIFY_STATUS, status() + ("error" to e.code))
            throw e
        }
    }

    fun signOut() {
        auth.signOut()
        prefs.edit().clear().apply()
        publish()
    }

    fun playlists(): SpotifyApi.PlaylistPage = api.editablePlaylists(userId())

    fun createPlaylist(name: String): SpotifyPlaylist =
        api.createPlaylist(name, "Songs discovered around me with Sonora.")

    fun setDefaultPlaylist(id: String, name: String) {
        prefs.edit().putString(KEY_PLAYLIST_ID, id).putString(KEY_PLAYLIST_NAME, name).apply()
        publish()
    }

    /**
     * The Spotify track for a history song: the stored ID from ACRCloud
     * (`confirmed = true`), or the best search result, which the user must confirm.
     */
    fun findTrack(songId: Long): Map<String, Any?> {
        val song = history.songDetail(songId)?.song
            ?: throw SpotifyException(SpotifyErrorCodes.NOT_FOUND, "That song is no longer in your history.")
        song.spotifyTrackId?.let { id ->
            return mapOf("trackId" to id, "title" to song.title, "artist" to song.artist, "album" to song.album, "confirmed" to true)
        }
        val match = api.searchTrack(song.title, song.artist)
            ?: throw SpotifyException(SpotifyErrorCodes.NOT_FOUND, "Couldn't find this song on Spotify.")
        return mapOf("trackId" to match.id, "title" to match.title, "artist" to match.artist, "album" to match.album, "confirmed" to false)
    }

    /**
     * Adds the song to a playlist exactly once. [trackId] is required when the
     * song had no stored Spotify ID and the user confirmed a search match.
     */
    fun addSong(songId: Long, playlistId: String, playlistName: String?, trackId: String?): AddResult {
        val song = history.songDetail(songId)?.song
            ?: throw SpotifyException(SpotifyErrorCodes.NOT_FOUND, "That song is no longer in your history.")
        val id = song.spotifyTrackId ?: trackId
            ?: throw SpotifyException(SpotifyErrorCodes.NEEDS_MATCH, "Confirm the Spotify match first.")
        if (song.spotifyTrackId == null) history.updateSpotifyTrackId(songId, id)

        val item = queue.enqueue(songId, PROVIDER, playlistId, playlistName, "spotify:track:$id")
        if (item.status == SyncStatus.COMPLETED) return AddResult.ALREADY_IN_PLAYLIST
        return push(item.id, playlistId, item.trackUri)
    }

    /** Retries adds that failed earlier (e.g. offline). Returns how many succeeded. */
    fun retryFailed(): Int {
        if (!auth.isSignedIn) return 0
        var done = 0
        for (item in queue.retryable(PROVIDER, MAX_ATTEMPTS)) {
            // Retrying can't bring back a deleted playlist.
            if (item.lastError == SpotifyErrorCodes.PLAYLIST_NOT_FOUND) continue
            try {
                push(item.id, item.playlistId, item.trackUri)
                done++
            } catch (e: SpotifyException) {
                if (e.code == SpotifyErrorCodes.NETWORK || e.code == SpotifyErrorCodes.RATE_LIMITED) break
            }
        }
        return done
    }

    /**
     * [song] switched to the Spotify version people usually see (see
     * [SpotifyVersionPicker]). Unchanged when Spotify isn't connected or the
     * lookup fails.
     */
    fun preferredVersion(song: RecognizedSong): RecognizedSong {
        if (!auth.isSignedIn) return song
        return try {
            lookUpVersion(song)
        } catch (e: SpotifyException) {
            Log.w(TAG, "Spotify version lookup failed: ${e.code}")
            song
        }
    }

    /**
     * Applies [preferredVersion] to songs saved since the last check, e.g.
     * while Spotify wasn't connected. Returns how many changed.
     */
    fun refreshVersions(): Int {
        if (!auth.isSignedIn) return 0
        var changed = 0
        for ((songId, song) in history.songsAfter(prefs.getLong(KEY_VERSIONS_CHECKED, 0))) {
            val preferred = try {
                lookUpVersion(song)
            } catch (e: SpotifyException) {
                break // Offline or rate limited; resume from here next time.
            }
            if (preferred != song) {
                history.updateSpotifyVersion(songId, ArtworkResolver.enrich(preferred))
                changed++
            }
            prefs.edit().putLong(KEY_VERSIONS_CHECKED, songId).apply()
        }
        return changed
    }

    private fun lookUpVersion(song: RecognizedSong): RecognizedSong {
        val track = SpotifyVersionPicker.choose(song.title, song.artist, api.searchTracks(song.title, song.artist))
            ?: return song
        return SpotifyVersionPicker.apply(song, track)
    }

    fun syncStatusForSong(songId: Long) = queue.forSong(songId).filter { it.provider == PROVIDER }.map { it.toMap() }

    private fun push(queueId: Long, playlistId: String, trackUri: String): AddResult = try {
        // The playlist may already have the song (added in Spotify itself); never add it twice.
        if (api.playlistContains(playlistId, trackUri)) {
            queue.markCompleted(queueId)
            AddResult.ALREADY_IN_PLAYLIST
        } else {
            api.addToPlaylist(playlistId, listOf(trackUri))
            queue.markCompleted(queueId)
            AddResult.ADDED
        }
    } catch (e: SpotifyException) {
        // A 404 here means the playlist itself is gone (deleted, or no longer
        // shared); the track ID came from Spotify's own search.
        val error = if (e.httpStatus == 404) playlistGone(playlistId) else e
        queue.markFailed(queueId, error.code)
        throw error
    }

    /** Forgets a default playlist that no longer exists, so the app asks for a new one. */
    private fun playlistGone(playlistId: String): SpotifyException {
        val name = prefs.getString(KEY_PLAYLIST_NAME, null)
        if (prefs.getString(KEY_PLAYLIST_ID, null) == playlistId) {
            prefs.edit().remove(KEY_PLAYLIST_ID).remove(KEY_PLAYLIST_NAME).apply()
            publish()
        }
        val label = name?.let { "\"$it\"" } ?: "That playlist"
        return SpotifyException(
            SpotifyErrorCodes.PLAYLIST_NOT_FOUND,
            "$label no longer exists on Spotify. Choose another playlist in Sonora.",
            404,
        )
    }

    private fun userId(): String = prefs.getString(KEY_USER_ID, null)
        ?: api.me().also { prefs.edit().putString(KEY_USER_ID, it.id).putString(KEY_NAME, it.displayName).apply() }.id

    private fun publish() = SonoraEvents.emit(BridgeContract.Events.SPOTIFY_STATUS, status())

    companion object {
        private const val TAG = "SpotifyManager"
        private const val PROVIDER = "spotify"
        private const val MAX_ATTEMPTS = 5
        private const val PREFS = "sonora_spotify"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_NAME = "display_name"
        private const val KEY_PLAYLIST_ID = "default_playlist_id"
        private const val KEY_PLAYLIST_NAME = "default_playlist_name"
        private const val KEY_VERSIONS_CHECKED = "versions_checked_song_id"

        @Volatile
        private var instance: SpotifyManager? = null

        fun get(context: Context): SpotifyManager =
            instance ?: synchronized(this) { instance ?: SpotifyManager(context).also { instance = it } }

        fun isRedirect(uri: Uri?): Boolean =
            uri?.scheme == SpotifyAuth.REDIRECT_SCHEME && uri.host == SpotifyAuth.REDIRECT_HOST
    }
}
