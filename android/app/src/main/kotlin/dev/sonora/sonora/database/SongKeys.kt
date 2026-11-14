package dev.sonora.sonora.database

import dev.sonora.sonora.recognition.RecognizedSong
import java.util.Locale

/**
 * Identity of a song across recognitions, so repeated matches share one
 * `songs` row. Preference: provider track ID, then ISRC, then normalised
 * title and artist.
 */
object SongKeys {
    fun keyFor(song: RecognizedSong): String = when {
        song.providerId.isNotBlank() -> "id:${song.provider}:${song.providerId}"
        !song.isrc.isNullOrBlank() -> "isrc:${song.isrc.uppercase(Locale.ROOT)}"
        else -> "meta:${normalise(song.title)}|${normalise(song.artist)}"
    }

    fun normalise(value: String): String =
        value.lowercase(Locale.ROOT).replace(Regex("[^\\p{L}\\p{N}]+"), " ").trim()

    /** Escapes LIKE wildcards so a user's search text matches literally (use with ESCAPE '\'). */
    fun likePattern(query: String): String =
        "%" + query.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%"
}
