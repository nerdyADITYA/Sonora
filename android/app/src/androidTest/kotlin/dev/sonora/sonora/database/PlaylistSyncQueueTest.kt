package dev.sonora.sonora.database

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import dev.sonora.sonora.recognition.RecognizedSong
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class PlaylistSyncQueueTest {

    private lateinit var database: SonoraDatabase
    private lateinit var history: HistoryRepository
    private lateinit var queue: PlaylistSyncQueue
    private var songId = 0L

    @Before
    fun setUp() {
        database = SonoraDatabase(InstrumentationRegistry.getInstrumentation().targetContext, name = null)
        history = HistoryRepository(database)
        queue = PlaylistSyncQueue(database)
        songId = history.record(
            RecognizedSong(
                provider = "acrcloud", providerId = "a", title = "Closer", artist = "The Chainsmokers",
                album = null, releaseDate = null, durationMs = null, isrc = null, spotifyTrackId = "T1",
                artworkUrl = null, confidence = null, recognizedAt = 1,
            ),
            RecognitionSource.MANUAL,
        ).songId
    }

    @After
    fun tearDown() = database.close()

    @Test
    fun enqueueTwiceReturnsTheSameRow() {
        val first = queue.enqueue(songId, "spotify", "P1", "Mix", "spotify:track:T1")
        val second = queue.enqueue(songId, "spotify", "P1", "Mix", "spotify:track:T1")

        assertEquals(first.id, second.id)
        assertEquals(SyncStatus.PENDING, second.status)
        assertEquals(1, queue.forSong(songId).size)
    }

    @Test
    fun completedRowsStayCompletedAndAreNotRetried() {
        val item = queue.enqueue(songId, "spotify", "P1", "Mix", "spotify:track:T1")
        queue.markCompleted(item.id)

        assertEquals(SyncStatus.COMPLETED, queue.enqueue(songId, "spotify", "P1", "Mix", "spotify:track:T1").status)
        assertTrue(queue.retryable("spotify", 5).isEmpty())
    }

    @Test
    fun failuresAreRetriedUntilTheAttemptLimit() {
        val item = queue.enqueue(songId, "spotify", "P1", "Mix", "spotify:track:T1")
        queue.markFailed(item.id, "NETWORK_UNAVAILABLE")

        val retry = queue.retryable("spotify", 2).single()
        assertEquals(SyncStatus.FAILED, retry.status)
        assertEquals(1, retry.attempts)
        assertEquals("NETWORK_UNAVAILABLE", retry.lastError)

        queue.markFailed(item.id, "NETWORK_UNAVAILABLE")
        assertTrue(queue.retryable("spotify", 2).isEmpty())
    }

    @Test
    fun differentPlaylistsAreSeparateRows() {
        queue.enqueue(songId, "spotify", "P1", "Mix", "spotify:track:T1")
        queue.enqueue(songId, "spotify", "P2", "Chill", "spotify:track:T1")

        assertEquals(listOf("P1", "P2"), queue.forSong(songId).map { it.playlistId })
    }

    @Test
    fun deletingTheSongRemovesItsQueueRows() {
        queue.enqueue(songId, "spotify", "P1", "Mix", "spotify:track:T1")

        history.deleteSong(songId)

        assertNull(queue.find(songId, "spotify", "P1"))
    }
}
