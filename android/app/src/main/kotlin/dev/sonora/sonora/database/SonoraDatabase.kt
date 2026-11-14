package dev.sonora.sonora.database

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

/**
 * Local recognition history (plain SQLite; see docs/ARCHITECTURE.md for why not Room).
 *
 * - `songs`: one row per distinct song ([SongKeys.keyFor]).
 * - `recognition_events`: one row per time a song was recognised.
 *
 * Only metadata is stored. Audio is never written anywhere.
 */
class SonoraDatabase(context: Context, name: String? = NAME) :
    SQLiteOpenHelper(context.applicationContext, name, null, VERSION) {

    override fun onConfigure(db: SQLiteDatabase) {
        db.setForeignKeyConstraintsEnabled(true)
    }

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE songs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                song_key TEXT NOT NULL UNIQUE,
                provider TEXT NOT NULL,
                provider_id TEXT,
                title TEXT NOT NULL,
                artist TEXT NOT NULL,
                album TEXT,
                artwork_url TEXT,
                release_date TEXT,
                duration_ms INTEGER,
                isrc TEXT,
                spotify_track_id TEXT,
                spotify_album_id TEXT,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
            )
            """.trimIndent(),
        )
        db.execSQL(
            """
            CREATE TABLE recognition_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                song_id INTEGER NOT NULL REFERENCES songs(id) ON DELETE CASCADE,
                recognized_at INTEGER NOT NULL,
                provider TEXT NOT NULL,
                confidence REAL,
                recognition_mode TEXT NOT NULL,
                source TEXT NOT NULL
            )
            """.trimIndent(),
        )
        db.execSQL("CREATE INDEX idx_events_recognized_at ON recognition_events(recognized_at)")
        db.execSQL("CREATE INDEX idx_events_song ON recognition_events(song_id)")
        createSyncQueue(db)
    }

    /** Version 3: songs added to streaming-service playlists, with retry state. */
    private fun createSyncQueue(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE playlist_sync_queue (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                song_id INTEGER NOT NULL REFERENCES songs(id) ON DELETE CASCADE,
                provider TEXT NOT NULL,
                playlist_id TEXT NOT NULL,
                playlist_name TEXT,
                track_uri TEXT NOT NULL,
                status TEXT NOT NULL,
                attempts INTEGER NOT NULL DEFAULT 0,
                last_error TEXT,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                UNIQUE (song_id, provider, playlist_id)
            )
            """.trimIndent(),
        )
    }

    /** Step-by-step migrations. Never drop user history. */
    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 2) {
            db.execSQL("ALTER TABLE songs ADD COLUMN spotify_album_id TEXT")
        }
        if (oldVersion < 3) {
            createSyncQueue(db)
        }
    }

    companion object {
        @Volatile
        private var shared: SonoraDatabase? = null

        /** The single process-wide helper; every repository shares it so SQLite has one connection pool. */
        fun shared(context: Context): SonoraDatabase =
            shared ?: synchronized(this) { shared ?: SonoraDatabase(context).also { shared = it } }

        const val NAME = "sonora.db"
        const val VERSION = 3
    }
}
