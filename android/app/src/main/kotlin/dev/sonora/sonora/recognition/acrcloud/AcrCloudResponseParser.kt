package dev.sonora.sonora.recognition.acrcloud

import android.util.Log
import dev.sonora.sonora.BuildConfig
import dev.sonora.sonora.recognition.MatchSelector
import dev.sonora.sonora.recognition.RecognitionErrorCodes
import dev.sonora.sonora.recognition.RecognitionOutcome
import dev.sonora.sonora.recognition.RecognizedSong
import org.json.JSONException
import org.json.JSONObject

/**
 * Maps ACRCloud's identify JSON to a [RecognitionOutcome].
 * Kept free of SDK types so it compiles whether or not the SDK is present.
 */
object AcrCloudResponseParser {
    const val PROVIDER = "acrcloud"
    private const val TAG = "AcrCloudParser"

    // https://docs.acrcloud.com — status codes
    private const val SUCCESS = 0
    private const val NO_RESULT = 1001
    private const val CANNOT_FINGERPRINT = 2004
    private const val TIMEOUT = 2005
    private const val HTTP_ERROR = 3000
    private const val INVALID_ACCESS_KEY = 3001
    private const val LIMIT_EXCEEDED = 3003
    private const val INVALID_SIGNATURE = 3014
    private const val QPS_LIMIT = 3015

    fun parse(json: String?, now: Long = System.currentTimeMillis()): RecognitionOutcome {
        if (json.isNullOrBlank()) {
            return RecognitionOutcome.Failure(RecognitionErrorCodes.PROVIDER_ERROR, "Empty response from ACRCloud.")
        }
        return try {
            val root = JSONObject(json)
            val status = root.optJSONObject("status")
            when (val code = status?.optInt("code", -1) ?: -1) {
                SUCCESS -> parseMatch(root, now)
                NO_RESULT, CANNOT_FINGERPRINT -> RecognitionOutcome.NoMatch
                TIMEOUT, HTTP_ERROR -> failure(RecognitionErrorCodes.NETWORK_UNAVAILABLE, code)
                INVALID_ACCESS_KEY, INVALID_SIGNATURE -> failure(RecognitionErrorCodes.INVALID_CREDENTIALS, code)
                LIMIT_EXCEEDED, QPS_LIMIT -> failure(RecognitionErrorCodes.QUOTA_EXCEEDED, code)
                else -> failure(RecognitionErrorCodes.PROVIDER_ERROR, code)
            }
        } catch (e: JSONException) {
            RecognitionOutcome.Failure(RecognitionErrorCodes.PROVIDER_ERROR, "Unreadable response from ACRCloud.")
        }
    }

    private fun failure(code: String, providerCode: Int) =
        RecognitionOutcome.Failure(code, "ACRCloud status $providerCode.")

    /** Considers every candidate ACRCloud returns; see [MatchSelector] for the rules. */
    private fun parseMatch(root: JSONObject, now: Long): RecognitionOutcome {
        val music = root.optJSONObject("metadata")?.optJSONArray("music") ?: return RecognitionOutcome.NoMatch
        val candidates = (0 until music.length()).mapNotNull { i ->
            music.optJSONObject(i)?.let { MatchSelector.Candidate(it.toSong(now), it.optInt("score", -1).takeIf { s -> s >= 0 }) }
        }
        if (BuildConfig.DEBUG) {
            // Song metadata only, debug builds only, to tune MatchSelector. Info level:
            // Samsung builds drop debug-level app logs.
            candidates.forEachIndexed { i, c ->
                Log.i(TAG, "candidate $i: ${c.song.title} / ${c.song.artist} (score ${c.score}, released ${c.song.releaseDate})")
            }
        }
        val chosen = MatchSelector.choose(candidates)
        if (BuildConfig.DEBUG) {
            Log.i(TAG, chosen?.let { "chosen: ${it.song.title} / ${it.song.artist}, confident=${it.confident}" } ?: "chosen: none")
        }
        chosen ?: return RecognitionOutcome.NoMatch
        return RecognitionOutcome.Match(chosen.song, chosen.confident)
    }

    private fun JSONObject.toSong(now: Long): RecognizedSong {
        val best = this
        val artists = best.optJSONArray("artists")
        val artistNames = buildList {
            for (i in 0 until (artists?.length() ?: 0)) {
                artists?.optJSONObject(i)?.optString("name")?.takeIf { it.isNotBlank() }?.let(::add)
            }
        }

        val spotify = best.optJSONObject("external_metadata")?.optJSONObject("spotify")
        val spotifyTrackId = spotify?.optJSONObject("track")?.optStringOrNull("id")
        val spotifyAlbumId = spotify?.optJSONObject("album")?.optStringOrNull("id")

        return RecognizedSong(
                provider = PROVIDER,
                providerId = best.optStringOrNull("acrid") ?: "",
                title = best.optStringOrNull("title") ?: "Unknown title",
                artist = artistNames.joinToString(", ").ifBlank { "Unknown artist" },
                album = best.optJSONObject("album")?.optStringOrNull("name"),
                releaseDate = best.optStringOrNull("release_date"),
                durationMs = best.optInt("duration_ms", 0).takeIf { it > 0 },
                isrc = best.optJSONObject("external_ids")?.optStringOrNull("isrc"),
                spotifyTrackId = spotifyTrackId,
                spotifyAlbumId = spotifyAlbumId,
                // The identify response has no cover art; ArtworkResolver fills this in.
                artworkUrl = null,
                confidence = best.optInt("score", -1).takeIf { it >= 0 }?.let { it / 100.0 },
                playOffsetMs = best.optInt("play_offset_ms", -1).takeIf { it >= 0 },
                recognizedAt = now,
            )
    }

    private fun JSONObject.optStringOrNull(key: String): String? =
        if (has(key) && !isNull(key)) optString(key).takeIf { it.isNotBlank() } else null
}
