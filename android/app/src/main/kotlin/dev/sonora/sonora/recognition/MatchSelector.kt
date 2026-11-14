package dev.sonora.sonora.recognition

import dev.sonora.sonora.database.SongKeys

/**
 * Chooses which of a provider's candidates to trust. Pure logic, unit-tested.
 *
 * Real scores from a Galaxy S24 Ultra (2026-11-14, ambient, ACRCloud):
 * correct matches at 58, 70, 73, 82, 100; wrong ones at 28 (an unrelated
 * upload for Drake's "God's Plan") and 64 (a re-release of Ed Sheeran's
 * "Shape of You" credited to another artist). One cut-off can't separate
 * them, so there are three bands:
 * - below [MIN_SCORE]: rejected;
 * - [MIN_SCORE] to [CONFIDENT_SCORE]: accepted only once a second sample
 *   agrees ([confirms]); ambient listening re-checks soon to get it;
 * - [CONFIDENT_SCORE] and up: accepted.
 * Among same-title candidates near the best score, the earliest release wins,
 * because re-uploads and copies come after the original.
 */
object MatchSelector {

    const val MIN_SCORE = 50
    const val CONFIDENT_SCORE = 70

    /** How close to the best score a same-title candidate must be to compete on release date. */
    const val NEAR_BEST = 10

    data class Candidate(val song: RecognizedSong, val score: Int?)

    data class Selection(val song: RecognizedSong, val confident: Boolean)

    fun choose(candidates: List<Candidate>): Selection? {
        // A provider that reports no score is trusted as-is.
        val accepted = candidates.filter { (it.score ?: 100) >= MIN_SCORE }
        val best = accepted.maxByOrNull { it.score ?: 100 } ?: return null
        val bestScore = best.score ?: 100
        val bestTitle = SongKeys.normalise(best.song.title)

        val chosen = accepted
            .filter { SongKeys.normalise(it.song.title) == bestTitle && (it.score ?: 100) >= bestScore - NEAR_BEST }
            .sortedWith(
                compareBy<Candidate> { it.song.releaseDate.isNullOrBlank() } // dated first
                    .thenBy { it.song.releaseDate ?: "" } // ISO dates sort chronologically
                    .thenByDescending { it.score ?: 100 },
            )
            .first()
        return Selection(chosen.song, confident = bestScore >= CONFIDENT_SCORE)
    }

    /** True when [later] is the same song as an unconfirmed [earlier] match (title and first artist). */
    fun confirms(earlier: RecognizedSong, later: RecognizedSong): Boolean =
        SongKeys.normalise(earlier.title) == SongKeys.normalise(later.title) &&
            primaryArtist(earlier) == primaryArtist(later)

    private fun primaryArtist(song: RecognizedSong) = SongKeys.normalise(song.artist.substringBefore(","))
}
