package dev.sonora.sonora.services

/**
 * Decides when the next ambient check runs. Pure logic, unit-tested.
 *
 * Every recognition is a paid ACRCloud request, so the policy:
 * - only sends audio that passed the loudness probe,
 * - waits out the rest of a matched song before checking again,
 * - backs off after repeated no-matches,
 * - stops sending once the daily budget is used up.
 */
object ListeningPolicy {
    const val PROBE_MS = 3_000
    /** 12 s, not 10: ACRCloud scores rise with a longer sample, and it costs no extra request. */
    const val CAPTURE_MS = 12_000

    /**
     * Probe level needed before a full capture. A loudness gate, not a music
     * classifier: loud speech also passes. -50 dBFS is a quiet room plus
     * background music at normal volume on the S24 Ultra; tune with real data.
     */
    const val MIN_LEVEL_DBFS = -50.0

    const val DAILY_REQUEST_BUDGET = 200

    const val QUIET_DELAY_MS = 20_000L
    const val SILENT_DELAY_MS = 30_000L
    const val ERROR_DELAY_MS = 60_000L
    const val NO_MATCH_BASE_DELAY_MS = 30_000L
    const val NO_MATCH_MAX_DELAY_MS = 120_000L
    const val AFTER_MATCH_MIN_DELAY_MS = 45_000L
    const val AFTER_MATCH_MAX_DELAY_MS = 240_000L
    const val AFTER_MATCH_DEFAULT_DELAY_MS = 120_000L
    const val SONG_END_MARGIN_MS = 5_000L

    /** How often to check for a connection again while offline. */
    const val OFFLINE_RECHECK_MS = 60_000L

    /** Idle waits are multiplied by this while battery saver is on. */
    const val POWER_SAVE_FACTOR = 2

    /**
     * A 40–69 score match is re-checked straight away (the music is still
     * playing); a second agreeing sample confirms it.
     */
    const val CONFIRM_DELAY_MS = 1_000L

    /** Extra quick samples while a match is unconfirmed, when a sample comes back with no result. */
    const val CONFIRM_RETRIES = 2

    /** An unconfirmed match expires if no agreeing sample arrives within this time. */
    const val CONFIRM_WINDOW_MS = 3 * 60_000L

    /** Same track again within this window is not re-announced or re-saved (checked in the database). */
    const val DUPLICATE_WINDOW_MS = 15 * 60_000L

    /** 30 s, 60 s, 120 s, 120 s, ... */
    fun delayAfterNoMatch(consecutiveNoMatches: Int): Long {
        val shift = (consecutiveNoMatches - 1).coerceIn(0, 6)
        return (NO_MATCH_BASE_DELAY_MS shl shift).coerceAtMost(NO_MATCH_MAX_DELAY_MS)
    }

    /** Waits until the matched song should have finished, within bounds. */
    fun delayAfterMatch(durationMs: Int?, playOffsetMs: Int?, captureMs: Int = CAPTURE_MS): Long {
        if (durationMs == null || playOffsetMs == null || durationMs <= 0) return AFTER_MATCH_DEFAULT_DELAY_MS
        // The offset refers to the start of the sample; the sample itself already took captureMs.
        val remaining = durationMs.toLong() - playOffsetMs - captureMs + SONG_END_MARGIN_MS
        return remaining.coerceIn(AFTER_MATCH_MIN_DELAY_MS, AFTER_MATCH_MAX_DELAY_MS)
    }

    /**
     * Idle waits (quiet room, no match, offline) are doubled under battery
     * saver. Waits that follow a match are left alone so a new song isn't missed.
     */
    fun idleDelay(delayMs: Long, powerSave: Boolean): Long = if (powerSave) delayMs * POWER_SAVE_FACTOR else delayMs
}
