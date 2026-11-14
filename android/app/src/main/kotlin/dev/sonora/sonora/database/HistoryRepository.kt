package dev.sonora.sonora.database

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import dev.sonora.sonora.bridge.BridgeContract
import dev.sonora.sonora.bridge.SonoraEvents
import dev.sonora.sonora.recognition.RecognizedSong

/**
 * The only access point to recognition history. Thread-safe; calls block, so
 * run them off the main thread. Every change emits `history_changed`.
 */
class HistoryRepository internal constructor(private val database: SonoraDatabase) {

    /**
     * Saves a recognition. When [suppressWithinMs] is set and the same song
     * was recognised within that window, only the song's metadata is
     * refreshed and no event is added. Ambient listening uses this so
     * duplicates are caught even after an app restart.
     */
    @Synchronized
    fun record(song: RecognizedSong, source: RecognitionSource, suppressWithinMs: Long? = null): RecordResult {
        val db = database.writableDatabase
        val result: RecordResult
        db.beginTransaction()
        try {
            val (songId, storedArtwork) = upsertSong(db, song)
            val last = lastRecognizedAt(db, songId)
            val duplicate = suppressWithinMs != null && last != null && song.recognizedAt - last < suppressWithinMs

            val eventId = if (duplicate) {
                null
            } else {
                db.insertOrThrow(
                    "recognition_events",
                    null,
                    ContentValues().apply {
                        put("song_id", songId)
                        put("recognized_at", song.recognizedAt)
                        put("provider", song.provider)
                        put("confidence", song.confidence)
                        put("recognition_mode", MODE_ONLINE)
                        put("source", source.wire)
                    },
                )
            }
            result = RecordResult(songId, eventId, storedArtwork)
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
        if (!result.duplicate) notifyChanged()
        return result
    }

    @Synchronized
    fun updateArtwork(songId: Long, artworkUrl: String) {
        database.writableDatabase.update(
            "songs",
            ContentValues().apply { put("artwork_url", artworkUrl) },
            "id = ?",
            arrayOf(songId.toString()),
        )
        notifyChanged()
    }

    /** Saves a Spotify match the user confirmed, so it's never searched for again. */
    @Synchronized
    fun updateSpotifyTrackId(songId: Long, trackId: String) {
        database.writableDatabase.update(
            "songs",
            ContentValues().apply { put("spotify_track_id", trackId) },
            "id = ?",
            arrayOf(songId.toString()),
        )
        notifyChanged()
    }

    /**
     * Replaces the release details with another version of the same song
     * (album, cover, Spotify IDs). Null values clear the old version's data.
     */
    @Synchronized
    fun updateSpotifyVersion(songId: Long, song: RecognizedSong) {
        database.writableDatabase.update(
            "songs",
            ContentValues().apply {
                put("spotify_track_id", song.spotifyTrackId)
                put("spotify_album_id", song.spotifyAlbumId)
                put("album", song.album)
                put("release_date", song.releaseDate)
                put("isrc", song.isrc)
                put("artwork_url", song.artworkUrl)
                put("updated_at", System.currentTimeMillis())
            },
            "id = ?",
            arrayOf(songId.toString()),
        )
        notifyChanged()
    }

    /** Songs with an ID above [songId], oldest first. */
    fun songsAfter(songId: Long): List<Pair<Long, RecognizedSong>> {
        val ids = database.readableDatabase.rawQuery(
            "SELECT id FROM songs WHERE id > ? ORDER BY id",
            arrayOf(songId.toString()),
        ).use { cursor -> buildList { while (cursor.moveToNext()) add(cursor.getLong(0)) } }
        return ids.mapNotNull { id -> songDetail(id)?.let { id to it.song } }
    }

    fun history(
        query: String? = null,
        sort: HistorySort = HistorySort.NEWEST,
        limit: Int = DEFAULT_LIMIT,
        offset: Int = 0,
    ): List<HistoryEntry> {
        val search = query?.trim()?.takeIf { it.isNotEmpty() }
        val where = if (search == null) "" else "WHERE (s.title LIKE ?1 ESCAPE '\\' OR s.artist LIKE ?1 ESCAPE '\\' OR s.album LIKE ?1 ESCAPE '\\')"
        val args = listOfNotNull(search?.let(SongKeys::likePattern)).toTypedArray()
        val sql = "$SELECT_ENTRIES $where ORDER BY ${sort.orderBy} LIMIT ${limit.coerceIn(1, MAX_LIMIT)} OFFSET ${offset.coerceAtLeast(0)}"
        return database.readableDatabase.rawQuery(sql, args).use { cursor ->
            buildList { while (cursor.moveToNext()) add(cursor.toEntry()) }
        }
    }

    fun songDetail(songId: Long): SongDetail? {
        val entries = database.readableDatabase.rawQuery(
            "$SELECT_ENTRIES WHERE s.id = ? ORDER BY e.recognized_at DESC",
            arrayOf(songId.toString()),
        ).use { cursor -> buildList { while (cursor.moveToNext()) add(cursor.toEntry()) } }
        if (entries.isEmpty()) return null
        return SongDetail(
            songId = songId,
            song = entries.first().song,
            firstHeardAt = entries.last().song.recognizedAt,
            recognitions = entries,
        )
    }

    fun count(): Int = database.readableDatabase.rawQuery("SELECT COUNT(*) FROM recognition_events", null)
        .use { if (it.moveToFirst()) it.getInt(0) else 0 }

    /** Deletes one recognition; the song goes too when it has none left. */
    @Synchronized
    fun deleteEvent(eventId: Long) {
        val db = database.writableDatabase
        db.beginTransaction()
        try {
            db.delete("recognition_events", "id = ?", arrayOf(eventId.toString()))
            deleteOrphanSongs(db)
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
        notifyChanged()
    }

    /** Deletes a song and every recognition of it. */
    @Synchronized
    fun deleteSong(songId: Long) {
        database.writableDatabase.delete("songs", "id = ?", arrayOf(songId.toString()))
        notifyChanged()
    }

    @Synchronized
    fun clear() {
        val db = database.writableDatabase
        db.beginTransaction()
        try {
            db.delete("recognition_events", null, null)
            db.delete("songs", null, null)
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
        notifyChanged()
    }

    private fun upsertSong(db: SQLiteDatabase, song: RecognizedSong): Pair<Long, String?> {
        val key = SongKeys.keyFor(song)
        val existing = db.rawQuery("SELECT id, artwork_url FROM songs WHERE song_key = ?", arrayOf(key)).use {
            if (it.moveToFirst()) it.getLong(0) to it.getStringOrNull(1) else null
        }
        val now = System.currentTimeMillis()
        val values = ContentValues().apply {
            put("provider", song.provider)
            put("provider_id", song.providerId.ifBlank { null })
            put("title", song.title)
            put("artist", song.artist)
            put("updated_at", now)
            // Never overwrite known metadata with blanks from a sparser match.
            song.album?.let { put("album", it) }
            song.artworkUrl?.let { put("artwork_url", it) }
            song.releaseDate?.let { put("release_date", it) }
            song.durationMs?.let { put("duration_ms", it) }
            song.isrc?.let { put("isrc", it) }
            song.spotifyTrackId?.let { put("spotify_track_id", it) }
            song.spotifyAlbumId?.let { put("spotify_album_id", it) }
        }
        if (existing != null) {
            db.update("songs", values, "id = ?", arrayOf(existing.first.toString()))
            return existing.first to (song.artworkUrl ?: existing.second)
        }
        values.put("song_key", key)
        values.put("created_at", now)
        return db.insertOrThrow("songs", null, values) to song.artworkUrl
    }

    private fun lastRecognizedAt(db: SQLiteDatabase, songId: Long): Long? =
        db.rawQuery(
            "SELECT MAX(recognized_at) FROM recognition_events WHERE song_id = ?",
            arrayOf(songId.toString()),
        ).use { if (it.moveToFirst() && !it.isNull(0)) it.getLong(0) else null }

    private fun deleteOrphanSongs(db: SQLiteDatabase) {
        db.execSQL("DELETE FROM songs WHERE id NOT IN (SELECT DISTINCT song_id FROM recognition_events)")
    }

    private fun notifyChanged() {
        SonoraEvents.emit(BridgeContract.Events.HISTORY_CHANGED)
    }

    private fun Cursor.toEntry(): HistoryEntry = HistoryEntry(
        eventId = getLong(0),
        songId = getLong(1),
        source = RecognitionSource.parse(getStringOrNull(4)),
        song = RecognizedSong(
            provider = getString(3),
            providerId = getStringOrNull(5) ?: "",
            title = getString(6),
            artist = getString(7),
            album = getStringOrNull(8),
            artworkUrl = getStringOrNull(9),
            releaseDate = getStringOrNull(10),
            durationMs = if (isNull(11)) null else getInt(11),
            isrc = getStringOrNull(12),
            spotifyTrackId = getStringOrNull(13),
            spotifyAlbumId = getStringOrNull(15),
            confidence = if (isNull(14)) null else getDouble(14),
            recognizedAt = getLong(2),
        ),
    )

    private fun Cursor.getStringOrNull(index: Int): String? = if (isNull(index)) null else getString(index)

    companion object {
        const val DEFAULT_LIMIT = 200
        private const val MAX_LIMIT = 500
        private const val MODE_ONLINE = "online"

        private const val SELECT_ENTRIES = """
            SELECT e.id, e.song_id, e.recognized_at, e.provider, e.source,
                   s.provider_id, s.title, s.artist, s.album, s.artwork_url,
                   s.release_date, s.duration_ms, s.isrc, s.spotify_track_id, e.confidence,
                   s.spotify_album_id
            FROM recognition_events e JOIN songs s ON s.id = e.song_id
        """

        @Volatile
        private var instance: HistoryRepository? = null

        /** Process-wide instance shared by the service and the bridge. */
        fun get(context: Context): HistoryRepository =
            instance ?: synchronized(this) {
                instance ?: HistoryRepository(SonoraDatabase.shared(context)).also { instance = it }
            }
    }
}
