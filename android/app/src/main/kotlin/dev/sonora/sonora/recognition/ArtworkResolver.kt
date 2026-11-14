package dev.sonora.sonora.recognition

import android.util.Log
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

/**
 * Finds album artwork for a match. ACRCloud's identify response carries none.
 *
 * Order:
 * 1. Spotify oEmbed, when ACRCloud returned a Spotify track ID (exact match, no key needed).
 * 2. iTunes Search by artist and title, accepted only when both match.
 *
 * Only song metadata (track ID or title and artist) is sent. Never audio.
 * Failures return null; artwork is cosmetic.
 */
object ArtworkResolver {
    private const val TAG = "ArtworkResolver"
    private const val TIMEOUT_MS = 4_000

    fun resolve(song: RecognizedSong): String? =
        song.spotifyTrackId?.let(::fromSpotify) ?: fromITunes(song.title, song.artist)

    private fun fromSpotify(trackId: String): String? {
        val trackUrl = "https://open.spotify.com/track/${encode(trackId)}"
        val json = get("https://open.spotify.com/oembed?url=${encode(trackUrl)}") ?: return null
        return JSONObject(json).optString("thumbnail_url").takeIf { it.startsWith("https://") }
    }

    private fun fromITunes(title: String, artist: String): String? {
        val primaryArtist = artist.substringBefore(",").trim()
        val term = encode("$primaryArtist $title")
        val json = get("https://itunes.apple.com/search?term=$term&entity=song&limit=5") ?: return null
        val results = JSONObject(json).optJSONArray("results") ?: return null

        for (i in 0 until results.length()) {
            val item = results.optJSONObject(i) ?: continue
            val sameTitle = normalise(item.optString("trackName")).startsWith(normalise(title))
            val sameArtist = normalise(item.optString("artistName")).contains(normalise(primaryArtist))
            if (sameTitle && sameArtist) {
                // iTunes serves any square size by rewriting the dimensions in the URL.
                return item.optString("artworkUrl100")
                    .takeIf { it.startsWith("https://") }
                    ?.replace("100x100bb", "600x600bb")
            }
        }
        return null
    }

    private fun get(url: String): String? {
        val connection = URL(url).openConnection() as HttpURLConnection
        return try {
            connection.connectTimeout = TIMEOUT_MS
            connection.readTimeout = TIMEOUT_MS
            connection.setRequestProperty("Accept", "application/json")
            if (connection.responseCode != HttpURLConnection.HTTP_OK) return null
            connection.inputStream.bufferedReader().use { it.readText() }
        } catch (e: Exception) {
            Log.w(TAG, "Artwork lookup failed: ${e.javaClass.simpleName}")
            null
        } finally {
            connection.disconnect()
        }
    }

    private fun encode(value: String) = URLEncoder.encode(value, "UTF-8")

    private fun normalise(value: String) =
        value.lowercase().replace(Regex("[^\\p{L}\\p{N}]+"), " ").trim()
}
