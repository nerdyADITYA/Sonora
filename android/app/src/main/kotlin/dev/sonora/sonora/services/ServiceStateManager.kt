package dev.sonora.sonora.services

import dev.sonora.sonora.bridge.BridgeContract
import dev.sonora.sonora.bridge.SonoraEvents
import dev.sonora.sonora.recognition.RecognizedSong

/** What the ambient listener is doing right now. Wire names are the lowercase forms. */
enum class ListeningPhase(val wire: String) {
    STOPPED("stopped"),
    WAITING("waiting"), // Between checks, microphone off.
    LISTENING("listening"), // Microphone on: loudness probe, then the full sample.
    MATCHING("matching"),
    PAUSED_BUDGET("paused_budget"), // Daily request budget used up.
    MICROPHONE_BLOCKED("microphone_blocked"), // Silence: privacy toggle or mic busy.
}

/**
 * Process-wide listening state, owned by the service and read by the bridge.
 * Every change is published as a `listening_status` event.
 */
object ServiceStateManager {

    data class Snapshot(
        val phase: ListeningPhase = ListeningPhase.STOPPED,
        val nextCheckAt: Long? = null,
        val requestsToday: Int = 0,
        val dailyBudget: Int = ListeningPolicy.DAILY_REQUEST_BUDGET,
        val lastSong: RecognizedSong? = null,
        val lastError: String? = null,
    ) {
        val listening: Boolean get() = phase != ListeningPhase.STOPPED

        fun toMap(): Map<String, Any?> = mapOf(
            "listening" to listening,
            "available" to true,
            "phase" to phase.wire,
            "nextCheckAt" to nextCheckAt,
            "requestsToday" to requestsToday,
            "dailyBudget" to dailyBudget,
            "lastSong" to lastSong?.toMap(),
            "lastError" to lastError,
        )
    }

    @Volatile
    var snapshot = Snapshot()
        private set

    @Synchronized
    fun update(transform: (Snapshot) -> Snapshot) {
        snapshot = transform(snapshot)
        SonoraEvents.emit(BridgeContract.Events.LISTENING_STATUS, snapshot.toMap())
    }

    fun announceSong(song: RecognizedSong) {
        update { it.copy(lastSong = song, lastError = null) }
        SonoraEvents.emit(BridgeContract.Events.SONG_RECOGNIZED, song.toMap())
    }
}
