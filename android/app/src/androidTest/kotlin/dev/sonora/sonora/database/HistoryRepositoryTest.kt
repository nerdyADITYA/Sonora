package dev.sonora.sonora.database

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import dev.sonora.sonora.recognition.RecognizedSong
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/** Runs against real SQLite on the device, using an in-memory database. */
@RunWith(AndroidJUnit4::class)
class HistoryRepositoryTest {

    private lateinit var database: SonoraDatabase
    private lateinit var repo: HistoryRepository

    @Before
    fun setUp() {
        database = SonoraDatabase(InstrumentationRegistry.getInstrumentation().targetContext, name = null)
        repo = HistoryRepository(database)
    }

    @After
    fun tearDown() = database.close()

    private fun song(
        id: String,
        title: String,
        artist: String = "Sia",
        at: Long = 1_000_000L,
        artwork: String? = null,
        album: String? = null,
    ) = RecognizedSong(
        provider = "acrcloud",
        providerId = id,
        title = title,
        artist = artist,
        album = album,
        releaseDate = null,
        durationMs = 200_000,
        isrc = null,
        spotifyTrackId = null,
        artworkUrl = artwork,
        confidence = 0.9,
        recognizedAt = at,
    )

    @Test
    fun recordsAndListsNewestFirst() {
        repo.record(song("a", "Snowman", at = 1_000), RecognitionSource.MANUAL)
        repo.record(song("b", "Chandelier", at = 2_000), RecognitionSource.AMBIENT)

        val entries = repo.history()

        assertEquals(listOf("Chandelier", "Snowman"), entries.map { it.song.title })
        assertEquals(RecognitionSource.AMBIENT, entries.first().source)
        assertEquals(2, repo.count())
    }

    @Test
    fun ambientDuplicateWithinWindowIsSuppressed() {
        val window = 15 * 60_000L
        val first = repo.record(song("a", "Snowman", at = 0), RecognitionSource.AMBIENT, window)
        val repeat = repo.record(song("a", "Snowman", at = 60_000), RecognitionSource.AMBIENT, window)
        val later = repo.record(song("a", "Snowman", at = window + 1), RecognitionSource.AMBIENT, window)

        assertFalse(first.duplicate)
        assertTrue(repeat.duplicate)
        assertFalse(later.duplicate)
        assertEquals(first.songId, later.songId)
        assertEquals(2, repo.count())
    }

    @Test
    fun manualRecognitionsAreNeverSuppressed() {
        repo.record(song("a", "Snowman", at = 0), RecognitionSource.MANUAL)
        repo.record(song("a", "Snowman", at = 1), RecognitionSource.MANUAL)

        assertEquals(2, repo.count())
        assertEquals(1, repo.history().map { it.songId }.distinct().size)
    }

    @Test
    fun storedArtworkAndAlbumSurviveASparserMatch() {
        val first = repo.record(song("a", "Snowman", artwork = "https://img/1", album = "Everyday"), RecognitionSource.MANUAL)
        val second = repo.record(song("a", "Snowman", at = 2_000_000), RecognitionSource.MANUAL)

        assertEquals("https://img/1", second.storedArtworkUrl)
        val detail = repo.songDetail(first.songId)!!
        assertEquals("Everyday", detail.song.album)
        assertEquals("https://img/1", detail.song.artworkUrl)
        assertEquals(2, detail.recognitions.size)
        assertEquals(1_000_000L, detail.firstHeardAt)
    }

    @Test
    fun searchMatchesTitleArtistAndAlbumLiterally() {
        repo.record(song("a", "Snowman"), RecognitionSource.MANUAL)
        repo.record(song("b", "Bad Guy", artist = "Billie Eilish"), RecognitionSource.MANUAL)
        repo.record(song("c", "100% Pure", album = "Hits_2026"), RecognitionSource.MANUAL)

        assertEquals(listOf("Bad Guy"), repo.history(query = "billie").map { it.song.title })
        assertEquals(listOf("100% Pure"), repo.history(query = "100%").map { it.song.title })
        assertEquals(listOf("100% Pure"), repo.history(query = "hits_").map { it.song.title })
        assertTrue(repo.history(query = "zzz").isEmpty())
    }

    @Test
    fun sortsByTitleAndArtist() {
        repo.record(song("a", "Snowman", artist = "Sia"), RecognitionSource.MANUAL)
        repo.record(song("b", "bad guy", artist = "Billie Eilish"), RecognitionSource.MANUAL)
        repo.record(song("c", "Chandelier", artist = "Adele"), RecognitionSource.MANUAL)

        assertEquals(listOf("bad guy", "Chandelier", "Snowman"), repo.history(sort = HistorySort.TITLE).map { it.song.title })
        assertEquals(listOf("Adele", "Billie Eilish", "Sia"), repo.history(sort = HistorySort.ARTIST).map { it.song.artist })
    }

    @Test
    fun deletingTheLastRecognitionRemovesTheSong() {
        val recorded = repo.record(song("a", "Snowman"), RecognitionSource.MANUAL)

        repo.deleteEvent(recorded.eventId!!)

        assertTrue(repo.history().isEmpty())
        assertNull(repo.songDetail(recorded.songId))
    }

    @Test
    fun deletingASongRemovesAllItsRecognitions() {
        val a = repo.record(song("a", "Snowman", at = 1), RecognitionSource.MANUAL)
        repo.record(song("a", "Snowman", at = 2), RecognitionSource.MANUAL)
        repo.record(song("b", "Chandelier"), RecognitionSource.MANUAL)

        repo.deleteSong(a.songId)

        assertEquals(listOf("Chandelier"), repo.history().map { it.song.title })
    }

    @Test
    fun clearRemovesEverything() {
        repo.record(song("a", "Snowman"), RecognitionSource.MANUAL)
        repo.record(song("b", "Chandelier"), RecognitionSource.AMBIENT)

        repo.clear()

        assertEquals(0, repo.count())
    }

    @Test
    fun spotifyVersionReplacesReleaseDetailsAndListsNewerSongs() {
        val first = repo.record(song("a", "God's Plan", artist = "Drake", album = "Scary Hours", artwork = "https://old"), RecognitionSource.MANUAL)
        val second = repo.record(song("b", "Snowman"), RecognitionSource.MANUAL)

        val stored = repo.songDetail(first.songId)!!.song
        repo.updateSpotifyVersion(
            first.songId,
            stored.copy(album = "Scorpion", artworkUrl = "https://new", spotifyTrackId = "T2", isrc = null),
        )

        val updated = repo.songDetail(first.songId)!!.song
        assertEquals("Scorpion", updated.album)
        assertEquals("https://new", updated.artworkUrl)
        assertEquals("T2", updated.spotifyTrackId)
        assertEquals(listOf(second.songId), repo.songsAfter(first.songId).map { it.first })
        assertEquals(2, repo.songsAfter(0).size)
    }
}
