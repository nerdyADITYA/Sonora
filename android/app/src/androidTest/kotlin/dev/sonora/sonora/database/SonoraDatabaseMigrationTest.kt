package dev.sonora.sonora.database

import android.database.sqlite.SQLiteDatabase
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import dev.sonora.sonora.recognition.RecognizedSong
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

/** Upgrading a real version-1 database must keep history and add new columns. */
@RunWith(AndroidJUnit4::class)
class SonoraDatabaseMigrationTest {

    private val context = InstrumentationRegistry.getInstrumentation().targetContext
    private lateinit var file: File

    @Before
    fun setUp() {
        file = File(context.cacheDir, "migration-test.db").also { it.delete() }
    }

    @After
    fun tearDown() {
        SQLiteDatabase.deleteDatabase(file)
    }

    @Test
    fun version1HistorySurvivesUpgradeAndGainsAlbumId() {
        // The exact v1 schema shipped in 0.4.0.
        SQLiteDatabase.openOrCreateDatabase(file, null).use { v1 ->
            v1.execSQL(
                """CREATE TABLE songs (id INTEGER PRIMARY KEY AUTOINCREMENT, song_key TEXT NOT NULL UNIQUE,
                provider TEXT NOT NULL, provider_id TEXT, title TEXT NOT NULL, artist TEXT NOT NULL, album TEXT,
                artwork_url TEXT, release_date TEXT, duration_ms INTEGER, isrc TEXT, spotify_track_id TEXT,
                created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)""",
            )
            v1.execSQL(
                """CREATE TABLE recognition_events (id INTEGER PRIMARY KEY AUTOINCREMENT,
                song_id INTEGER NOT NULL REFERENCES songs(id) ON DELETE CASCADE, recognized_at INTEGER NOT NULL,
                provider TEXT NOT NULL, confidence REAL, recognition_mode TEXT NOT NULL, source TEXT NOT NULL)""",
            )
            v1.execSQL(
                "INSERT INTO songs VALUES (1, 'id:acrcloud:a', 'acrcloud', 'a', 'Snowman', 'Sia', NULL, NULL, NULL, NULL, NULL, 'TRACK', 0, 0)",
            )
            v1.execSQL("INSERT INTO recognition_events VALUES (1, 1, 1000, 'acrcloud', 0.9, 'online', 'ambient')")
            v1.version = 1
        }

        val database = SonoraDatabase(context, name = file.absolutePath)
        try {
            val repo = HistoryRepository(database)
            assertEquals(listOf("Snowman"), repo.history().map { it.song.title })

            // A new match of the same song fills in the album ID added in v2.
            repo.record(
                RecognizedSong(
                    provider = "acrcloud", providerId = "a", title = "Snowman", artist = "Sia", album = null,
                    releaseDate = null, durationMs = null, isrc = null, spotifyTrackId = "TRACK",
                    spotifyAlbumId = "ALBUM", artworkUrl = null, confidence = null, recognizedAt = 2000,
                ),
                RecognitionSource.MANUAL,
            )
            assertEquals("ALBUM", repo.songDetail(1)!!.song.spotifyAlbumId)
            assertEquals(2, repo.count())
        } finally {
            database.close()
        }
    }
}
