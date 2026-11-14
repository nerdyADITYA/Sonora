package dev.sonora.sonora.spotify

import org.json.JSONArray
import org.json.JSONObject

data class SpotifyUser(val id: String, val displayName: String)

data class SpotifyPlaylist(
    val id: String,
    val name: String,
    val ownerId: String,
    val collaborative: Boolean,
    val trackCount: Int,
    val imageUrl: String?,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "name" to name,
        "trackCount" to trackCount,
        "imageUrl" to imageUrl,
    )
}

data class SpotifyTrack(
    val id: String,
    val title: String,
    val artist: String,
    val album: String?,
    val albumId: String? = null,
    val releaseDate: String? = null,
    val imageUrl: String? = null,
    /** 0-100; Spotify may omit it for apps in Development Mode. */
    val popularity: Int? = null,
    val isrc: String? = null,
) {
    val uri: String get() = "spotify:track:$id"
}

/**
 * The Spotify Web API calls Sonora needs, using the February 2026 endpoints
 * (`/me/playlists`, `/playlists/{id}/items`). Retries once with a fresh token
 * on 401. Blocking; call off the main thread.
 */
class SpotifyApi(private val auth: SpotifyAuth) {

    fun me(): SpotifyUser {
        val json = get("$BASE/me")
        return SpotifyUser(json.getString("id"), json.optString("display_name").ifBlank { json.getString("id") })
    }

    /** Playlists in the user's library, split into ones they can add to and a count of the rest. */
    data class PlaylistPage(val editable: List<SpotifyPlaylist>, val hiddenCount: Int)

    /**
     * Playlists the user can add to: their own and collaborative ones. Spotify
     * refuses adds to playlists another account owns, even ones you follow.
     */
    fun editablePlaylists(userId: String, max: Int = 200): PlaylistPage {
        val result = mutableListOf<SpotifyPlaylist>()
        var hidden = 0
        var url: String? = "$BASE/me/playlists?limit=50"
        while (url != null && result.size < max) {
            val page = get(url)
            val items = page.optJSONArray("items") ?: JSONArray()
            for (i in 0 until items.length()) {
                val p = items.optJSONObject(i) ?: continue
                val playlist = p.toPlaylist() ?: continue
                if (playlist.ownerId == userId || playlist.collaborative) result += playlist else hidden++
            }
            url = page.optString("next").takeIf { it.startsWith("https://") }
        }
        return PlaylistPage(result, hidden)
    }

    fun createPlaylist(name: String, description: String): SpotifyPlaylist {
        val body = JSONObject().put("name", name).put("description", description).put("public", false)
        val json = send("POST", "$BASE/me/playlists", body)
        return json.toPlaylist() ?: throw SpotifyException(SpotifyErrorCodes.API_ERROR, "Spotify didn't return the new playlist.")
    }

    /** Pages through the playlist (own or collaborative only) looking for [trackUri]. */
    fun playlistContains(playlistId: String, trackUri: String): Boolean {
        var url: String? = "$BASE/playlists/${SpotifyHttp.encode(playlistId)}/items?limit=100"
        while (url != null) {
            val page = get(url)
            val items = page.optJSONArray("items") ?: JSONArray()
            for (i in 0 until items.length()) {
                val entry = items.optJSONObject(i) ?: continue
                // The item object was named "track" before February 2026 and "item" after.
                val item = entry.optJSONObject("item") ?: entry.optJSONObject("track") ?: continue
                if (item.optString("uri") == trackUri) return true
            }
            url = page.optString("next").takeIf { it.startsWith("https://") }
        }
        return false
    }

    fun addToPlaylist(playlistId: String, trackUris: List<String>) {
        send("POST", "$BASE/playlists/${SpotifyHttp.encode(playlistId)}/items", JSONObject().put("uris", JSONArray(trackUris)))
    }

    fun track(id: String): SpotifyTrack? = get("$BASE/tracks/${SpotifyHttp.encode(id)}").toTrack()

    /** Best match for a song without a Spotify ID. The caller must let the user confirm it. */
    fun searchTrack(title: String, artist: String): SpotifyTrack? {
        val query = "track:${quoted(title)} artist:${quoted(artist.substringBefore(","))}"
        val json = get("$BASE/search?type=track&limit=5&q=${SpotifyHttp.encode(query)}")
        val items = json.optJSONObject("tracks")?.optJSONArray("items") ?: return null
        return (0 until items.length()).firstNotNullOfOrNull { items.optJSONObject(it)?.toTrack() }
    }

    /** Search results for a title and primary artist, in Spotify's relevance order. */
    fun searchTracks(title: String, artist: String, limit: Int = 10): List<SpotifyTrack> {
        val query = "track:${quoted(title)} artist:${quoted(artist.substringBefore(","))}"
        val json = get("$BASE/search?type=track&limit=$limit&q=${SpotifyHttp.encode(query)}")
        val items = json.optJSONObject("tracks")?.optJSONArray("items") ?: return emptyList()
        return (0 until items.length()).mapNotNull { items.optJSONObject(it)?.toTrack() }
    }

    private fun quoted(value: String) = "\"" + value.trim().replace("\"", "") + "\""

    private fun get(url: String): JSONObject = send("GET", url, null)

    private fun send(method: String, url: String, body: JSONObject?): JSONObject {
        var response = SpotifyHttp.request(method, url, auth.accessToken(), jsonBody = body)
        if (response.status == 401) {
            response = SpotifyHttp.request(method, url, auth.accessToken(forceRefresh = true), jsonBody = body)
        }
        when {
            response.status in 200..299 -> return response.json()
            response.status == 429 -> throw SpotifyException(SpotifyErrorCodes.RATE_LIMITED, "Spotify is limiting requests. Try again later.", 429)
            response.status == 403 -> throw SpotifyException(
                SpotifyErrorCodes.FORBIDDEN,
                "Spotify refused the request. Check the account is added under User Management and the owner has Premium.",
                403,
            )
            else -> throw SpotifyException(SpotifyErrorCodes.API_ERROR, "Spotify error ${response.status}.", response.status)
        }
    }

    private fun JSONObject.toPlaylist(): SpotifyPlaylist? {
        val id = optString("id").ifBlank { return null }
        // The track count moved from "tracks" to "items" in February 2026.
        val count = (optJSONObject("items") ?: optJSONObject("tracks"))?.optInt("total", 0) ?: 0
        return SpotifyPlaylist(
            id = id,
            name = optString("name").ifBlank { "Untitled playlist" },
            ownerId = optJSONObject("owner")?.optString("id") ?: "",
            collaborative = optBoolean("collaborative", false),
            trackCount = count,
            imageUrl = optJSONArray("images")?.optJSONObject(0)?.optString("url")?.takeIf { it.startsWith("https://") },
        )
    }

    private fun JSONObject.toTrack(): SpotifyTrack? {
        val id = optString("id").ifBlank { return null }
        val artists = optJSONArray("artists")
        val artistNames = (0 until (artists?.length() ?: 0)).mapNotNull { artists?.optJSONObject(it)?.optString("name") }
        val album = optJSONObject("album")
        return SpotifyTrack(
            id = id,
            title = optString("name"),
            artist = artistNames.joinToString(", "),
            album = album?.optString("name")?.ifBlank { null },
            albumId = album?.optString("id")?.ifBlank { null },
            releaseDate = album?.optString("release_date")?.ifBlank { null },
            imageUrl = album?.optJSONArray("images")?.optJSONObject(0)?.optString("url")?.takeIf { it.startsWith("https://") },
            popularity = if (has("popularity")) optInt("popularity") else null,
            isrc = optJSONObject("external_ids")?.optString("isrc")?.ifBlank { null },
        )
    }

    private companion object {
        const val BASE = "https://api.spotify.com/v1"
    }
}
