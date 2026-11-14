package dev.sonora.sonora.recognition

import java.net.URLEncoder

/** Spotify links that show a song without starting playback. */
object SpotifyLinks {
    /**
     * Spotify autoplays track links, and album links with a highlighted track.
     * ACRCloud's album ID can also point to a compilation rather than the
     * original release. A search link opens Spotify's search with the song as
     * the top result, and never plays (verified on a Galaxy S24 Ultra,
     * 2026-11-14). Opens in the browser when Spotify isn't installed.
     */
    fun view(title: String, artist: String): String =
        "https://open.spotify.com/search/" + URLEncoder.encode(searchQuery(title, artist), "UTF-8").replace("+", "%20")

    /** Title plus the first credited artist; extra credits make results worse. */
    fun searchQuery(title: String, artist: String): String =
        "${title.trim()} ${artist.substringBefore(",").trim()}".trim()
}
