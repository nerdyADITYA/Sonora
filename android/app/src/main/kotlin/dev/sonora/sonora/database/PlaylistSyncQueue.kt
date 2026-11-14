package dev.sonora.sonora.database

import android.content.ContentValues
import android.content.Context
import android.database.Cursor

enum class SyncStatus(val wire: String) {
    PENDING("pending"),
    COMPLETED("completed"),
    FAILED("failed"),
    ;

    companion object {
        fun parse(value: String?) = entries.firstOrNull { it.wire == value } ?: PENDING
    }
}

data class SyncItem(
    val id: Long,
    val songId: Long,
    val provider: String,
    val playlistId: String,
    val playlistName: String?,
    val trackUri: String,
    val status: SyncStatus,
    val attempts: Int,
    val lastError: String?,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "playlistId" to playlistId,
        "playlistName" to playlistName,
        "status" to status.wire,
        "attempts" to attempts,
        "lastError" to lastError,
    )
}

/**
 * One row per (song, provider, playlist). The unique key means a retried or
 * repeated add never creates a second entry; a completed row means "already
 * in that playlist, don't add again".
 */
class PlaylistSyncQueue internal constructor(private val database: SonoraDatabase) {

    /** Returns the existing row for this song and playlist, or a new pending one. */
    @Synchronized
    fun enqueue(songId: Long, provider: String, playlistId: String, playlistName: String?, trackUri: String): SyncItem {
        find(songId, provider, playlistId)?.let { return it }
        val now = System.currentTimeMillis()
        database.writableDatabase.insertOrThrow(
            TABLE,
            null,
            ContentValues().apply {
                put("song_id", songId)
                put("provider", provider)
                put("playlist_id", playlistId)
                put("playlist_name", playlistName)
                put("track_uri", trackUri)
                put("status", SyncStatus.PENDING.wire)
                put("attempts", 0)
                put("created_at", now)
                put("updated_at", now)
            },
        )
        return find(songId, provider, playlistId)!!
    }

    @Synchronized
    fun markCompleted(id: Long) = update(id, SyncStatus.COMPLETED, null, incrementAttempts = true)

    @Synchronized
    fun markFailed(id: Long, error: String) = update(id, SyncStatus.FAILED, error, incrementAttempts = true)

    /** Failed or interrupted adds that may be retried. */
    fun retryable(provider: String, maxAttempts: Int): List<SyncItem> = query(
        "provider = ? AND status != ? AND attempts < ?",
        arrayOf(provider, SyncStatus.COMPLETED.wire, maxAttempts.toString()),
    )

    fun forSong(songId: Long): List<SyncItem> = query("song_id = ?", arrayOf(songId.toString()))

    fun find(songId: Long, provider: String, playlistId: String): SyncItem? = query(
        "song_id = ? AND provider = ? AND playlist_id = ?",
        arrayOf(songId.toString(), provider, playlistId),
    ).firstOrNull()

    private fun update(id: Long, status: SyncStatus, error: String?, incrementAttempts: Boolean) {
        val db = database.writableDatabase
        db.execSQL(
            "UPDATE $TABLE SET status = ?, last_error = ?, updated_at = ?" +
                (if (incrementAttempts) ", attempts = attempts + 1" else "") + " WHERE id = ?",
            arrayOf<Any?>(status.wire, error, System.currentTimeMillis(), id),
        )
    }

    private fun query(where: String, args: Array<String>): List<SyncItem> =
        database.readableDatabase.query(TABLE, null, where, args, null, null, "created_at ASC").use { c ->
            buildList { while (c.moveToNext()) add(c.toItem()) }
        }

    private fun Cursor.toItem() = SyncItem(
        id = getLong(getColumnIndexOrThrow("id")),
        songId = getLong(getColumnIndexOrThrow("song_id")),
        provider = getString(getColumnIndexOrThrow("provider")),
        playlistId = getString(getColumnIndexOrThrow("playlist_id")),
        playlistName = getColumnIndexOrThrow("playlist_name").let { if (isNull(it)) null else getString(it) },
        trackUri = getString(getColumnIndexOrThrow("track_uri")),
        status = SyncStatus.parse(getString(getColumnIndexOrThrow("status"))),
        attempts = getInt(getColumnIndexOrThrow("attempts")),
        lastError = getColumnIndexOrThrow("last_error").let { if (isNull(it)) null else getString(it) },
    )

    companion object {
        private const val TABLE = "playlist_sync_queue"

        @Volatile
        private var instance: PlaylistSyncQueue? = null

        fun get(context: Context): PlaylistSyncQueue =
            instance ?: synchronized(this) {
                instance ?: PlaylistSyncQueue(SonoraDatabase.shared(context)).also { instance = it }
            }
    }
}
