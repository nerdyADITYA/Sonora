package dev.sonora.sonora.bridge

/**
 * A song the app was opened for (from the notification). Flutter takes it once
 * it is ready, so a cold start isn't missed; an `open_song` event covers a
 * running app.
 */
object LaunchRequests {
    @Volatile
    private var songId: Long? = null

    fun offer(id: Long) {
        songId = id
        SonoraEvents.emit(BridgeContract.Events.OPEN_SONG, mapOf("songId" to id))
    }

    @Synchronized
    fun take(): Long? = songId.also { songId = null }
}
