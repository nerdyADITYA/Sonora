package dev.sonora.sonora.services

import dev.sonora.sonora.recognition.RecognizedSong
import org.junit.Assert.assertEquals
import org.junit.Test

class ListeningStatusTextTest {

    private val song = RecognizedSong(
        provider = "acrcloud", providerId = "a", title = "Snowman", artist = "Sia", album = null,
        releaseDate = null, durationMs = null, isrc = null, spotifyTrackId = null, artworkUrl = null,
        confidence = null, recognizedAt = 0,
    )

    @Test
    fun `battery saver doubles idle waits only`() {
        assertEquals(40_000L, ListeningPolicy.idleDelay(20_000L, powerSave = true))
        assertEquals(20_000L, ListeningPolicy.idleDelay(20_000L, powerSave = false))
    }

    @Test
    fun `tile shows problems before the last song`() {
        val state = ServiceStateManager.Snapshot(phase = ListeningPhase.OFFLINE, lastSong = song)
        assertEquals("No internet", state.tileText())
        assertEquals("Snowman", state.copy(phase = ListeningPhase.WAITING).tileText())
        assertEquals("Listening", ServiceStateManager.Snapshot(phase = ListeningPhase.LISTENING).tileText())
        assertEquals("Daily limit reached", state.copy(phase = ListeningPhase.PAUSED_BUDGET).tileText())
    }

    @Test
    fun `notification mentions battery saver while waiting`() {
        val state = ServiceStateManager.Snapshot(phase = ListeningPhase.WAITING, powerSave = true)
        assertEquals("Listening for music · battery saver", state.statusText())
        assertEquals("Identifying…", state.copy(phase = ListeningPhase.MATCHING).statusText())
    }
}
