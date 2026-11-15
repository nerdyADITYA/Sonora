package dev.sonora.sonora.recognition

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class MatchSelectorTest {

    private fun song(title: String, artist: String, released: String? = null, score: Int? = null) = RecognizedSong(
        provider = "acrcloud", providerId = "$title/$artist", title = title, artist = artist,
        album = null, releaseDate = released, durationMs = null, isrc = null, spotifyTrackId = null,
        artworkUrl = null, confidence = score?.div(100.0), recognizedAt = 0,
    )

    private fun candidate(title: String, artist: String, score: Int?, released: String? = null) =
        MatchSelector.Candidate(song(title, artist, released, score), score)

    @Test
    fun `a weak unrelated match is rejected (God's Plan heard as a 28 score upload)`() {
        assertNull(MatchSelector.choose(listOf(candidate("Bad Things", "DrizzleDreJr", 28, "2018-02-16"))))
    }

    @Test
    fun `a 58 score match is kept but needs confirmation (the correct God's Plan)`() {
        val selection = MatchSelector.choose(listOf(candidate("God's Plan", "Drake", 58, "2018-01-20")))!!
        assertEquals("Drake", selection.song.artist)
        assertFalse(selection.confident)
    }

    @Test
    fun `70 and above is confident`() {
        assertTrue(MatchSelector.choose(listOf(candidate("Light Switch", "Charlie Puth", 70)))!!.confident)
        assertFalse(MatchSelector.choose(listOf(candidate("Light Switch", "Charlie Puth", 69)))!!.confident)
    }

    @Test
    fun `the original release beats a later re-release of the same title`() {
        val chosen = MatchSelector.choose(
            listOf(
                candidate("Shape of You", "Tony Modicano", 82, "2017-04-18"),
                candidate("Shape of You", "Ed Sheeran", 78, "2017-01-06"),
            ),
        )
        assertEquals("Ed Sheeran", chosen?.song?.artist)
    }

    @Test
    fun `a much weaker same-title candidate doesn't win on date alone`() {
        val chosen = MatchSelector.choose(
            listOf(
                candidate("Shape of You", "Ed Sheeran", 95, "2017-01-06"),
                candidate("Shape of You", "Old Cover Band", 72, "2001-01-01"),
            ),
        )
        assertEquals("Ed Sheeran", chosen?.song?.artist)
    }

    @Test
    fun `different titles never compete on date`() {
        val chosen = MatchSelector.choose(
            listOf(
                candidate("God's Plan", "Drake", 90, "2018-01-19"),
                candidate("Some Older Song", "Someone", 88, "1999-01-01"),
            ),
        )
        assertEquals("Drake", chosen?.song?.artist)
    }

    @Test
    fun `undated candidates lose ties to dated ones, and missing scores are trusted`() {
        val chosen = MatchSelector.choose(
            listOf(
                candidate("Closer", "Unknown upload", 90, null),
                candidate("Closer", "The Chainsmokers", null, "2016-07-29"),
            ),
        )
        assertEquals("The Chainsmokers", chosen?.song?.artist)
    }

    @Test
    fun `nothing at or above the floor means no match`() {
        assertNull(MatchSelector.choose(listOf(candidate("A", "B", 49), candidate("C", "D", 10))))
        assertNull(MatchSelector.choose(emptyList()))
    }

    @Test
    fun `40 to 49 is tentative, below 40 is nothing (Wo Noor heard at 43)`() {
        val heard = listOf(candidate("Wo Noor", "AP Dhillon", 43), candidate("Other", "X", 30))
        assertNull(MatchSelector.choose(heard))
        assertEquals("Wo Noor", MatchSelector.tentative(heard)!!.title)
        assertNull(MatchSelector.tentative(listOf(candidate("A", "B", 39))))
        assertNull(MatchSelector.tentative(listOf(candidate("A", "B", 55))))
        assertNull(MatchSelector.tentative(listOf(candidate("A", "B", null))))
    }

    @Test
    fun `a second sample confirms only the same title and first artist`() {
        val first = song("God's Plan", "Drake")
        assertTrue(MatchSelector.confirms(first, song("GOD'S PLAN!", "DRAKE, Someone")))
        assertFalse(MatchSelector.confirms(first, song("God's Plan", "A Cover Band")))
        assertFalse(MatchSelector.confirms(song("Shape of You", "Tony Modicano"), song("Shape of You", "Ed Sheeran")))
    }
}
