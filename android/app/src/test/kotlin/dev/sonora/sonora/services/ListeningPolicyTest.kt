package dev.sonora.sonora.services

import org.junit.Assert.assertEquals
import org.junit.Test

class ListeningPolicyTest {

    @Test
    fun `no-match delay doubles then caps`() {
        assertEquals(30_000L, ListeningPolicy.delayAfterNoMatch(1))
        assertEquals(60_000L, ListeningPolicy.delayAfterNoMatch(2))
        assertEquals(120_000L, ListeningPolicy.delayAfterNoMatch(3))
        assertEquals(120_000L, ListeningPolicy.delayAfterNoMatch(10))
    }

    @Test
    fun `after a match waits for the rest of the song`() {
        // 3:30 song, matched 60 s in: 210 - 60 - 10 (sample) + 5 (margin) = 145 s.
        assertEquals(143_000L, ListeningPolicy.delayAfterMatch(durationMs = 210_000, playOffsetMs = 60_000))
    }

    @Test
    fun `after a match the delay stays within bounds`() {
        // Matched near the end: at least the minimum.
        assertEquals(
            ListeningPolicy.AFTER_MATCH_MIN_DELAY_MS,
            ListeningPolicy.delayAfterMatch(durationMs = 200_000, playOffsetMs = 195_000),
        )
        // Very long track matched early: capped.
        assertEquals(
            ListeningPolicy.AFTER_MATCH_MAX_DELAY_MS,
            ListeningPolicy.delayAfterMatch(durationMs = 900_000, playOffsetMs = 0),
        )
    }

    @Test
    fun `missing duration or offset uses the default`() {
        assertEquals(ListeningPolicy.AFTER_MATCH_DEFAULT_DELAY_MS, ListeningPolicy.delayAfterMatch(null, 1_000))
        assertEquals(ListeningPolicy.AFTER_MATCH_DEFAULT_DELAY_MS, ListeningPolicy.delayAfterMatch(200_000, null))
    }

}
