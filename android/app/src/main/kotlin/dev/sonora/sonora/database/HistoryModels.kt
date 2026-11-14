package dev.sonora.sonora.database

import dev.sonora.sonora.recognition.RecognizedSong

/** How a recognition was triggered. */
enum class RecognitionSource(val wire: String) {
    MANUAL("manual"),
    AMBIENT("ambient"),
    ;

    companion object {
        fun parse(value: String?) = entries.firstOrNull { it.wire == value } ?: MANUAL
    }
}

enum class HistorySort(val wire: String, val orderBy: String) {
    NEWEST("newest", "e.recognized_at DESC"),
    OLDEST("oldest", "e.recognized_at ASC"),
    TITLE("title", "s.title COLLATE NOCASE ASC, e.recognized_at DESC"),
    ARTIST("artist", "s.artist COLLATE NOCASE ASC, s.title COLLATE NOCASE ASC, e.recognized_at DESC"),
    ;

    companion object {
        fun parse(value: String?) = entries.firstOrNull { it.wire == value } ?: NEWEST
    }
}

/** One recognition with its song, as listed in history. */
data class HistoryEntry(
    val eventId: Long,
    val songId: Long,
    val source: RecognitionSource,
    val song: RecognizedSong,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "eventId" to eventId,
        "songId" to songId,
        "source" to source.wire,
        "recognizedAt" to song.recognizedAt,
        "song" to song.toMap(),
    )
}

/** A song with every time it was recognised, newest first. */
data class SongDetail(
    val songId: Long,
    val song: RecognizedSong,
    val firstHeardAt: Long,
    val recognitions: List<HistoryEntry>,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "songId" to songId,
        "song" to song.toMap(),
        "firstHeardAt" to firstHeardAt,
        "timesHeard" to recognitions.size,
        "recognitions" to recognitions.map { it.toMap() },
    )
}

/** Result of [HistoryRepository.record]. */
data class RecordResult(
    val songId: Long,
    /** Null when suppressed as a duplicate. */
    val eventId: Long?,
    /** Artwork already stored for this song, if any. */
    val storedArtworkUrl: String?,
) {
    val duplicate: Boolean get() = eventId == null
}
