package dev.sonora.sonora.bridge

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import dev.sonora.sonora.audio.AudioCaptureManager
import dev.sonora.sonora.database.HistoryRepository
import dev.sonora.sonora.database.HistorySort
import dev.sonora.sonora.recognition.RecognitionErrorCodes
import dev.sonora.sonora.recognition.RecognitionManager
import dev.sonora.sonora.recognition.RecognitionOutcome
import dev.sonora.sonora.recognition.SpotifyLinks
import dev.sonora.sonora.services.ServiceStateManager
import dev.sonora.sonora.services.SonoraRecognitionService
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/** Asks the user for runtime permissions. Implemented by the hosting activity. */
fun interface PermissionRequester {
    /**
     * Requests the microphone and, on Android 13+, notifications. [onResult]
     * receives `microphone` and `notifications`, each "granted", "denied" or
     * "permanently_denied".
     */
    fun requestPermissions(onResult: (Map<String, String>) -> Unit)
}

/** Handles request/response calls from Flutter on [BridgeContract.CONTROL_CHANNEL]. */
class SonoraMethodChannel(
    private val context: Context,
    messenger: BinaryMessenger,
    private val recognition: RecognitionManager,
    private val permissions: PermissionRequester,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, BridgeContract.CONTROL_CHANNEL)
    private val history = HistoryRepository.get(context)
    private val databaseExecutor = Executors.newSingleThreadExecutor { Thread(it, "sonora-history") }
    private val mainHandler = Handler(Looper.getMainLooper())

    fun register() = channel.setMethodCallHandler(this)

    fun unregister() {
        channel.setMethodCallHandler(null)
        databaseExecutor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                BridgeContract.Methods.GET_PLATFORM_INFO ->
                    result.success(BridgeResponse.success(platformInfo()))

                BridgeContract.Methods.GET_LISTENING_STATUS ->
                    result.success(BridgeResponse.success(ServiceStateManager.snapshot.toMap()))

                BridgeContract.Methods.START_LISTENING -> result.success(startListening())

                BridgeContract.Methods.GET_RECOGNITION_HISTORY -> onDatabase(result) {
                    val entries = history.history(
                        query = call.argument<String>("query"),
                        sort = HistorySort.parse(call.argument<String>("sort")),
                        limit = call.argument<Int>("limit") ?: HistoryRepository.DEFAULT_LIMIT,
                        offset = call.argument<Int>("offset") ?: 0,
                    )
                    BridgeResponse.success(mapOf("entries" to entries.map { it.toMap() }, "total" to history.count()))
                }

                BridgeContract.Methods.GET_SONG_DETAIL -> {
                    val songId = call.longArgument("songId") ?: return result.success(invalid("songId"))
                    onDatabase(result) {
                        history.songDetail(songId)?.let { BridgeResponse.success(it.toMap()) }
                            ?: BridgeResponse.failure(NOT_FOUND, "That song is no longer in your history.")
                    }
                }

                BridgeContract.Methods.DELETE_RECOGNITION -> {
                    val eventId = call.longArgument("eventId") ?: return result.success(invalid("eventId"))
                    onDatabase(result) {
                        history.deleteEvent(eventId)
                        BridgeResponse.success()
                    }
                }

                BridgeContract.Methods.DELETE_SONG -> {
                    val songId = call.longArgument("songId") ?: return result.success(invalid("songId"))
                    onDatabase(result) {
                        history.deleteSong(songId)
                        BridgeResponse.success()
                    }
                }

                BridgeContract.Methods.CLEAR_RECOGNITION_HISTORY -> onDatabase(result) {
                    history.clear()
                    BridgeResponse.success()
                }

                BridgeContract.Methods.OPEN_IN_SPOTIFY -> result.success(
                    openInSpotify(call.argument<String>("title"), call.argument<String>("artist")),
                )

                BridgeContract.Methods.STOP_LISTENING -> {
                    SonoraRecognitionService.stop(context)
                    result.success(BridgeResponse.success())
                }

                BridgeContract.Methods.REQUEST_PERMISSIONS -> requestPermissions(result)

                BridgeContract.Methods.RECOGNIZE_ONCE -> recognizeOnce(result)

                BridgeContract.Methods.CANCEL_RECOGNITION -> {
                    recognition.cancel()
                    result.success(BridgeResponse.success())
                }

                in BridgeContract.Methods.PLANNED ->
                    result.success(
                        BridgeResponse.failure(
                            BridgeErrorCode.NOT_IMPLEMENTED,
                            "${call.method} is not available in this version.",
                        ),
                    )

                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to handle ${call.method}", e)
            result.success(
                BridgeResponse.failure(BridgeErrorCode.INTERNAL_ERROR, "Native error while handling ${call.method}."),
            )
        }
    }

    /** Runs [block] on the database thread and replies on the main thread. */
    private fun onDatabase(result: MethodChannel.Result, block: () -> Map<String, Any?>) {
        databaseExecutor.execute {
            val response = try {
                block()
            } catch (e: Exception) {
                Log.e(TAG, "History operation failed", e)
                BridgeResponse.failure(BridgeErrorCode.INTERNAL_ERROR, "Could not access your history.")
            }
            mainHandler.post { result.success(response) }
        }
    }

    /**
     * Shows the song in Spotify's search without starting playback. The link
     * is always built here on open.spotify.com, so this can't open arbitrary URLs.
     */
    private fun openInSpotify(title: String?, artist: String?): Map<String, Any?> {
        if (title.isNullOrBlank() || title.length > MAX_TEXT) return invalid("title")
        if (artist.isNullOrBlank() || artist.length > MAX_TEXT) return invalid("artist")
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(SpotifyLinks.view(title, artist)))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            BridgeResponse.success()
        } catch (e: ActivityNotFoundException) {
            BridgeResponse.failure(NO_APP, "No app can open Spotify links.")
        }
    }

    private fun MethodCall.longArgument(key: String): Long? = (argument<Any>(key) as? Number)?.toLong()

    private fun invalid(key: String) = BridgeResponse.failure(BridgeErrorCode.INVALID_ARGUMENT, "Missing or invalid '$key'.")

    private fun requestPermissions(result: MethodChannel.Result) {
        permissions.requestPermissions { statuses -> result.success(BridgeResponse.success(statuses)) }
    }

    private fun startListening(): Map<String, Any?> = when {
        !recognition.hasMicrophonePermission ->
            BridgeResponse.failure(AudioCaptureManager.PERMISSION_REQUIRED, "Microphone permission not granted.")
        recognition.isBusy ->
            BridgeResponse.failure(RecognitionErrorCodes.BUSY, "Wait for the current recognition to finish.")
        else -> {
            // Called from the visible app, which Android requires for microphone services.
            SonoraRecognitionService.start(context)
            BridgeResponse.success(ServiceStateManager.snapshot.toMap())
        }
    }

    private fun recognizeOnce(result: MethodChannel.Result) {
        recognition.recognizeOnce { outcome, elapsedMs ->
            val response = when (outcome) {
                is RecognitionOutcome.Match -> BridgeResponse.success(
                    mapOf("matched" to true, "song" to outcome.song.toMap(), "elapsedMs" to elapsedMs),
                )
                RecognitionOutcome.NoMatch -> BridgeResponse.success(
                    mapOf("matched" to false, "song" to null, "elapsedMs" to elapsedMs),
                )
                is RecognitionOutcome.Failure -> BridgeResponse.failure(outcome.code, outcome.message)
            }
            result.success(response)
        }
    }

    private fun platformInfo(): Map<String, Any?> = mapOf(
        "manufacturer" to Build.MANUFACTURER,
        "brand" to Build.BRAND,
        "model" to Build.MODEL,
        "device" to Build.DEVICE,
        "androidVersion" to Build.VERSION.RELEASE,
        "sdkInt" to Build.VERSION.SDK_INT,
        "securityPatch" to Build.VERSION.SECURITY_PATCH,
        "isSamsung" to Build.MANUFACTURER.equals("samsung", ignoreCase = true),
        "appVersion" to appVersionName(),
    )

    private fun appVersionName(): String? {
        val pm = context.packageManager
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getPackageInfo(context.packageName, PackageManager.PackageInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.getPackageInfo(context.packageName, 0)
        }
        return info.versionName
    }

    private companion object {
        const val TAG = "SonoraMethodChannel"
        const val NOT_FOUND = "NOT_FOUND"
        const val NO_APP = "NO_APP"
        const val MAX_TEXT = 300
    }
}
