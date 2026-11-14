package dev.sonora.sonora.spotify

import dev.sonora.sonora.recognition.RecognizedSong
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class SpotifyVersionPickerTest {

    private val scaryHours = SpotifyTrack(
        id = "scary", title = "God's Plan", artist = "Drake", album = "Scary Hours",
        albumId = "A1", releaseDate = "2018-01-20", imageUrl = "https://i/scary", popularity = 60,
    )
    private val scorpion = scaryHours.copy(
        id = "scorpion", album = "Scorpion", albumId = "A2", releaseDate = "2018-06-29",
        imageUrl = "https://i/scorpion", popularity = 85,
    )

    private val heard = RecognizedSong(
        provider = "acrcloud", providerId = "x", title = "God's Plan", artist = "Drake",
        album = "Scary Hours", releaseDate = "2018-01-20", durationMs = 198_000, isrc = "USCM51800004",
        spotifyTrackId = "scary", spotifyAlbumId = "A1", artworkUrl = "https://i/scary",
        confidence = 0.94, recognizedAt = 0,
    )

    @Test
    fun `the more popular release wins (God's Plan on Scorpion, not Scary Hours)`() {
        assertEquals("scorpion", SpotifyVersionPicker.choose("God's Plan", "Drake", listOf(scaryHours, scorpion))?.id)
    }

    @Test
    fun `without popularity Spotify's order decides`() {
        val results = listOf(scorpion.copy(popularity = null), scaryHours.copy(popularity = null))
        assertEquals("scorpion", SpotifyVersionPicker.choose("God's Plan", "Drake", results)?.id)
    }

    @Test
    fun `covers, remixes and other artists are ignored`() {
        val results = listOf(
            scorpion.copy(id = "cover", artist = "Some Cover Band", popularity = 99),
            scorpion.copy(id = "remix", title = "God's Plan (Remix)", popularity = 98),
            scaryHours,
        )
        assertEquals("scary", SpotifyVersionPicker.choose("GOD'S PLAN", "Drake", results)?.id)
    }

    @Test
    fun `a featured primary artist still matches`() {
        val track = scorpion.copy(artist = "Other, Drake")
        assertEquals("scorpion", SpotifyVersionPicker.choose("God's Plan", "Drake, Someone", listOf(track))?.id)
    }

    @Test
    fun `no matching result keeps the recognised version`() {
        assertNull(SpotifyVersionPicker.choose("God's Plan", "Drake", listOf(scorpion.copy(title = "Nice For What"))))
    }

    @Test
    fun `applying a version replaces album, cover and IDs but keeps the identity`() {
        val song = SpotifyVersionPicker.apply(heard, scorpion)
        assertEquals("scorpion", song.spotifyTrackId)
        assertEquals("A2", song.spotifyAlbumId)
        assertEquals("Scorpion", song.album)
        assertEquals("2018-06-29", song.releaseDate)
        assertEquals("https://i/scorpion", song.artworkUrl)
        assertEquals("x", song.providerId)
        assertEquals("God's Plan", song.title)
    }

    @Test
    fun `a different version without a cover drops the old cover so it is looked up again`() {
        assertNull(SpotifyVersionPicker.apply(heard, scorpion.copy(imageUrl = null)).artworkUrl)
    }
}
