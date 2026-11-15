package dev.sonora.sonora.bridge

/**
 * Names shared with the Dart side. Keep in sync with
 * `lib/core/constants/channel_names.dart` and `docs/ARCHITECTURE.md`.
 */
object BridgeContract {
    const val CONTROL_CHANNEL = "dev.sonora/control"
    const val EVENTS_CHANNEL = "dev.sonora/events"

    object Methods {
        const val GET_PLATFORM_INFO = "getPlatformInfo"
        const val GET_LISTENING_STATUS = "getListeningStatus"

        const val REQUEST_PERMISSIONS = "requestPermissions"
        const val RECOGNIZE_ONCE = "recognizeOnce"
        const val CANCEL_RECOGNITION = "cancelRecognition"
        const val START_LISTENING = "startListening"
        const val STOP_LISTENING = "stopListening"

        const val GET_RECOGNITION_HISTORY = "getRecognitionHistory"
        const val GET_SONG_DETAIL = "getSongDetail"
        const val DELETE_RECOGNITION = "deleteRecognition"
        const val DELETE_SONG = "deleteSong"
        const val CLEAR_RECOGNITION_HISTORY = "clearRecognitionHistory"
        const val OPEN_IN_SPOTIFY = "openInSpotify"
        const val GET_SPOTIFY_STATUS = "getSpotifyStatus"
        const val CONNECT_SPOTIFY = "connectSpotify"
        const val DISCONNECT_SPOTIFY = "disconnectSpotify"
        const val GET_SPOTIFY_PLAYLISTS = "getSpotifyPlaylists"
        const val CREATE_SPOTIFY_PLAYLIST = "createSpotifyPlaylist"
        const val SET_DEFAULT_SPOTIFY_PLAYLIST = "setDefaultSpotifyPlaylist"
        const val FIND_SPOTIFY_TRACK = "findSpotifyTrack"
        const val ADD_TO_SPOTIFY_PLAYLIST = "addToSpotifyPlaylist"
        const val GET_SPOTIFY_SYNC_STATUS = "getSpotifySyncStatus"
        const val RETRY_SPOTIFY_SYNC = "retrySpotifySync"

        const val OPEN_BATTERY_SETTINGS = "openBatterySettings"
        const val DISMISS_LISTENING_INTERRUPTION = "dismissListeningInterruption"
        const val REQUEST_ADD_TILE = "requestAddTile"
        const val TAKE_LAUNCH_SONG_ID = "takeLaunchSongId"
        const val GET_RECOGNITION_PROVIDER = "getRecognitionProvider"
        const val SET_ACRCLOUD_KEYS = "setAcrCloudKeys"
        const val CLEAR_ACRCLOUD_KEYS = "clearAcrCloudKeys"

        // Part of the published contract but implemented in later phases.
        // They answer with NOT_IMPLEMENTED instead of failing silently.
        const val GET_RECOGNITION_SETTINGS = "getRecognitionSettings"
        const val UPDATE_RECOGNITION_SETTINGS = "updateRecognitionSettings"

        val PLANNED = setOf(
            GET_RECOGNITION_SETTINGS,
            UPDATE_RECOGNITION_SETTINGS,
        )
    }

    object Events {
        const val BRIDGE_CONNECTED = "bridge_connected"
        const val RECOGNITION_CAPTURING = "recognition_capturing"
        const val RECOGNITION_MATCHING = "recognition_matching"
        const val LISTENING_STATUS = "listening_status"
        const val SONG_RECOGNIZED = "song_recognized"
        const val HISTORY_CHANGED = "history_changed"
        const val SPOTIFY_STATUS = "spotify_status"
        const val OPEN_SONG = "open_song"
    }
}

/** Structured error codes. The UI maps these to copy; raw exception text never crosses the bridge. */
enum class BridgeErrorCode {
    NOT_IMPLEMENTED,
    INVALID_ARGUMENT,
    INTERNAL_ERROR,
    ACTIVITY_UNAVAILABLE,
}

/** Builds the `{ success, data, error }` envelope every method returns. */
object BridgeResponse {
    fun success(data: Any? = null): Map<String, Any?> = mapOf(
        "success" to true,
        "data" to data,
        "error" to null,
    )

    fun failure(code: BridgeErrorCode, message: String): Map<String, Any?> = failure(code.name, message)

    /** For feature-specific codes such as RecognitionErrorCodes. */
    fun failure(code: String, message: String): Map<String, Any?> = mapOf(
        "success" to false,
        "data" to null,
        "error" to mapOf("code" to code, "message" to message),
    )
}
