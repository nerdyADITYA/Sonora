package dev.sonora.sonora.recognition

/** A song identified by a recognition provider. */
data class RecognizedSong(
    val provider: String,
    val providerId: String,
    val title: String,
    val artist: String,
    val album: String?,
    val releaseDate: String?,
    val durationMs: Int?,
    val isrc: String?,
    val spotifyTrackId: String?,
    /** Stored for later Spotify features. Not used for links: it can point to a compilation. */
    val spotifyAlbumId: String? = null,
    val artworkUrl: String?,
    /** 0.0–1.0, where the provider reports one. */
    val confidence: Double?,
    /** How far into the track the sample was, where reported. Used to skip re-checking the same song. */
    val playOffsetMs: Int? = null,
    val recognizedAt: Long,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "provider" to provider,
        "providerId" to providerId,
        "title" to title,
        "artist" to artist,
        "album" to album,
        "releaseDate" to releaseDate,
        "durationMs" to durationMs,
        "isrc" to isrc,
        "spotifyTrackId" to spotifyTrackId,
        "spotifyAlbumId" to spotifyAlbumId,
        "artworkUrl" to artworkUrl,
        "confidence" to confidence,
        "playOffsetMs" to playOffsetMs,
        "recognizedAt" to recognizedAt,
    )
}

sealed interface RecognitionOutcome {
    data class Match(val song: RecognizedSong) : RecognitionOutcome

    data object NoMatch : RecognitionOutcome

    /** [code] is one of [RecognitionErrorCodes]. */
    data class Failure(val code: String, val message: String) : RecognitionOutcome
}

object RecognitionErrorCodes {
    const val NOT_CONFIGURED = "NOT_CONFIGURED"
    const val PROVIDER_UNAVAILABLE = "PROVIDER_UNAVAILABLE"
    const val NETWORK_UNAVAILABLE = "NETWORK_UNAVAILABLE"
    const val INVALID_CREDENTIALS = "INVALID_CREDENTIALS"
    const val QUOTA_EXCEEDED = "QUOTA_EXCEEDED"
    const val PROVIDER_ERROR = "PROVIDER_ERROR"
    const val BUSY = "BUSY"
    const val LISTENING_ACTIVE = "LISTENING_ACTIVE"
}
