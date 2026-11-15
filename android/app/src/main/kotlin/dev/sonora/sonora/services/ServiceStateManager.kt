package dev.sonora.sonora.services

import dev.sonora.sonora.bridge.BridgeContract
import dev.sonora.sonora.bridge.SonoraEvents
import dev.sonora.sonora.recognition.RecognizedSong
import java.util.concurrent.CopyOnWriteArrayList

/** What the ambient listener is doing right now. Wire names are the lowercase forms. */
enum class ListeningPhase(val wire: String) {
    STOPPED("stopped"),
    WAITING("waiting"), // Between checks, microphone off.
    LISTENING("listening"), // Microphone on: loudness probe, then the full sample.
    MATCHING("matching"),
    PAUSED_BUDGET("paused_budget"), // Daily request budget used up.
    MICROPHONE_BLOCKED("microphone_blocked"), // Silence: privacy toggle or mic busy.
    OFFLINE("offline"), // No internet; microphone off, no requests counted.
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
        /** History row of [lastSong], for opening it from the notification. */
        val lastSongId: Long? = null,
        /** Playlist [lastSong] was saved to from the notification. */
        val savedTo: String? = null,
        /** Battery saver is on; idle checks are spaced out. */
        val powerSave: Boolean = false,
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
            "lastSongId" to lastSongId,
            "savedTo" to savedTo,
            "powerSave" to powerSave,
            "lastError" to lastError,
        )
    }

    @Volatile
    var snapshot = Snapshot()
        private set

    private val listeners = CopyOnWriteArrayList<(Snapshot) -> Unit>()

    /** In-process observers (the notification and the Quick Settings tile). */
    fun addListener(listener: (Snapshot) -> Unit) {
        listeners.addIfAbsent(listener)
    }

    fun removeListener(listener: (Snapshot) -> Unit) {
        listeners.remove(listener)
    }

    @Synchronized
    fun update(transform: (Snapshot) -> Snapshot) {
        snapshot = transform(snapshot)
        SonoraEvents.emit(BridgeContract.Events.LISTENING_STATUS, snapshot.toMap())
        listeners.forEach { it(snapshot) }
    }

    fun announceSong(song: RecognizedSong, songId: Long?) {
        update { it.copy(lastSong = song, lastSongId = songId, savedTo = null, lastError = null) }
        SonoraEvents.emit(BridgeContract.Events.SONG_RECOGNIZED, song.toMap())
    }
}

/** Status line for the notification. */
fun ServiceStateManager.Snapshot.statusText(): String = when (phase) {
    ListeningPhase.STOPPED -> "Stopped"
    ListeningPhase.WAITING -> if (powerSave) "Listening for music · battery saver" else "Listening for music"
    ListeningPhase.LISTENING -> "Listening…"
    ListeningPhase.MATCHING -> "Identifying…"
    ListeningPhase.PAUSED_BUDGET -> "Paused: daily limit of $dailyBudget reached"
    ListeningPhase.MICROPHONE_BLOCKED -> "Microphone blocked or in use"
    ListeningPhase.OFFLINE -> "Waiting for an internet connection"
}

/** Short status for the Quick Settings tile: problems first, else the last song. */
fun ServiceStateManager.Snapshot.tileText(): String = when (phase) {
    ListeningPhase.PAUSED_BUDGET -> "Daily limit reached"
    ListeningPhase.MICROPHONE_BLOCKED -> "Microphone blocked"
    ListeningPhase.OFFLINE -> "No internet"
    ListeningPhase.STOPPED -> "Off"
    else -> lastSong?.title ?: "Listening"
}
