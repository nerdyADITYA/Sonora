package dev.sonora.sonora.recognition

import org.junit.Assert.assertEquals
import org.junit.Test

class SpotifyLinksTest {

    @Test
    fun `search link uses title and first artist, URL-encoded`() {
        assertEquals(
            "https://open.spotify.com/search/Closer%20The%20Chainsmokers",
            SpotifyLinks.view("Closer", "The Chainsmokers, Halsey"),
        )
    }

    @Test
    fun `special characters are encoded, never passed through`() {
        assertEquals(
            "https://open.spotify.com/search/Don%27t%20Stop%20Me%20Now%20%26%2F%3F%20Queen",
            SpotifyLinks.view("Don't Stop Me Now &/?", "Queen"),
        )
    }
}
