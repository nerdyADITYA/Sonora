package dev.sonora.sonora.spotify

import dev.sonora.sonora.database.SongKeys
import dev.sonora.sonora.recognition.RecognizedSong

/**
 * Many songs are on Spotify more than once (single, EP, album, deluxe). The
 * recognition provider may name a less common release; Sonora prefers the
 * version Spotify users usually see, so the cover and playlist adds match the
 * Spotify app.
 */
object SpotifyVersionPicker {

    /**
     * The most popular search result with the same title and primary artist,
     * or null when none matches. Without popularity data, Spotify's own
     * relevance order decides.
     */
    fun choose(title: String, artist: String, results: List<SpotifyTrack>): SpotifyTrack? {
        val wantTitle = SongKeys.normalise(title)
        val wantArtist = SongKeys.normalise(artist.substringBefore(","))
        val same = results.filter { track ->
            SongKeys.normalise(track.title) == wantTitle &&
                track.artist.split(",").any { SongKeys.normalise(it) == wantArtist }
        }
        if (same.isEmpty()) return null
        return if (same.any { it.popularity != null }) same.maxBy { it.popularity ?: -1 } else same.first()
    }

    /** [song] with the release details of the chosen Spotify version. */
    fun apply(song: RecognizedSong, track: SpotifyTrack): RecognizedSong {
        val sameTrack = track.id == song.spotifyTrackId
        return song.copy(
            spotifyTrackId = track.id,
            spotifyAlbumId = track.albumId ?: song.spotifyAlbumId.takeIf { sameTrack },
            album = track.album ?: song.album,
            releaseDate = track.releaseDate ?: song.releaseDate,
            isrc = track.isrc ?: song.isrc,
            // Null lets the artwork lookup fetch the new version's cover.
            artworkUrl = track.imageUrl ?: song.artworkUrl.takeIf { sameTrack },
        )
    }
}
