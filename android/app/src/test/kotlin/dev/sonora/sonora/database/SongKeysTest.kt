package dev.sonora.sonora.database

import dev.sonora.sonora.recognition.RecognizedSong
import org.junit.Assert.assertEquals
import org.junit.Test

class SongKeysTest {

    private fun song(providerId: String = "", isrc: String? = null, title: String = "Snowman", artist: String = "Sia") =
        RecognizedSong(
            provider = "acrcloud",
            providerId = providerId,
            title = title,
            artist = artist,
            album = null,
            releaseDate = null,
            durationMs = null,
            isrc = isrc,
            spotifyTrackId = null,
            artworkUrl = null,
            confidence = null,
            recognizedAt = 0,
        )

    @Test
    fun `provider id wins`() {
        assertEquals("id:acrcloud:abc", SongKeys.keyFor(song(providerId = "abc", isrc = "USX")))
    }

    @Test
    fun `isrc is used without a provider id and is case-insensitive`() {
        assertEquals("isrc:USAT21703095", SongKeys.keyFor(song(isrc = "usat21703095")))
    }

    @Test
    fun `metadata fallback ignores case and punctuation`() {
        assertEquals(
            SongKeys.keyFor(song(title = "Snowman!", artist = "SIA")),
            SongKeys.keyFor(song(title = "  snowman ", artist = "Sia")),
        )
        assertEquals("meta:don t stop me now|queen", SongKeys.keyFor(song(title = "Don't Stop Me Now", artist = "Queen")))
    }

    @Test
    fun `like pattern escapes wildcards`() {
        assertEquals("%100\\% pure\\_love%", SongKeys.likePattern("100% pure_love"))
        assertEquals("%a\\\\b%", SongKeys.likePattern("a\\b"))
    }
}
