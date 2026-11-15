package dev.sonora.sonora.bridge

import android.app.StatusBarManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.graphics.drawable.Icon
import android.util.Log
import dev.sonora.sonora.audio.AudioCaptureManager
import dev.sonora.sonora.database.HistoryRepository
import dev.sonora.sonora.database.HistorySort
import dev.sonora.sonora.privacy.PrivacyConsent
import dev.sonora.sonora.recognition.RecognitionEngineFactory
import dev.sonora.sonora.recognition.AcrCloudCredentials
import dev.sonora.sonora.recognition.RecognitionErrorCodes
import dev.sonora.sonora.recognition.RecognitionManager
import dev.sonora.sonora.recognition.RecognitionOutcome
import dev.sonora.sonora.recognition.SpotifyLinks
import dev.sonora.sonora.R
import dev.sonora.sonora.services.ListeningRecovery
import dev.sonora.sonora.services.ListeningTileService
import dev.sonora.sonora.services.ServiceStateManager
import dev.sonora.sonora.spotify.SpotifyException
import dev.sonora.sonora.spotify.SpotifyManager
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
    private val networkExecutor = Executors.newSingleThreadExecutor { Thread(it, "sonora-spotify") }
    private val spotify = SpotifyManager.get(context)
    private val mainHandler = Handler(Looper.getMainLooper())

    fun register() = channel.setMethodCallHandler(this)

    fun unregister() {
        channel.setMethodCallHandler(null)
        databaseExecutor.shutdown()
        networkExecutor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                BridgeContract.Methods.GET_PLATFORM_INFO ->
                    result.success(BridgeResponse.success(platformInfo()))

                BridgeContract.Methods.GET_LISTENING_STATUS ->
                    result.success(BridgeResponse.success(listeningStatus()))

                BridgeContract.Methods.DISMISS_LISTENING_INTERRUPTION -> {
                    ListeningRecovery.markStopped(context)
                    result.success(BridgeResponse.success(listeningStatus()))
                }

                BridgeContract.Methods.OPEN_BATTERY_SETTINGS -> result.success(openBatterySettings())

                BridgeContract.Methods.REQUEST_ADD_TILE -> requestAddTile(result)

                BridgeContract.Methods.GET_PRIVACY_CONSENT ->
                    result.success(BridgeResponse.success(PrivacyConsent.toMap(context)))

                BridgeContract.Methods.SET_PRIVACY_CONSENT -> {
                    val accepted = call.argument<Boolean>("accepted")
                        ?: return result.success(invalid("accepted"))
                    if (accepted) {
                        PrivacyConsent.accept(context)
                    } else {
                        // Withdrawing consent stops any listening straight away.
                        recognition.cancel()
                        SonoraRecognitionService.stop(context)
                        PrivacyConsent.withdraw(context)
                    }
                    result.success(BridgeResponse.success(PrivacyConsent.toMap(context)))
                }

                BridgeContract.Methods.GET_RECOGNITION_PROVIDER ->
                    result.success(BridgeResponse.success(recognitionProvider()))

                BridgeContract.Methods.SET_ACRCLOUD_KEYS -> {
                    val response = try {
                        AcrCloudCredentials.get(context).save(
                            call.argument<String>("host"),
                            call.argument<String>("accessKey"),
                            call.argument<String>("accessSecret"),
                        )
                        BridgeResponse.success(recognitionProvider())
                    } catch (e: IllegalArgumentException) {
                        BridgeResponse.failure(BridgeErrorCode.INVALID_ARGUMENT, e.message ?: "Invalid keys.")
                    }
                    result.success(response)
                }

                BridgeContract.Methods.CLEAR_ACRCLOUD_KEYS -> {
                    AcrCloudCredentials.get(context).clear()
                    result.success(BridgeResponse.success(recognitionProvider()))
                }

                BridgeContract.Methods.TAKE_LAUNCH_SONG_ID ->
                    result.success(BridgeResponse.success(mapOf("songId" to LaunchRequests.take())))

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

                BridgeContract.Methods.GET_SPOTIFY_STATUS ->
                    result.success(BridgeResponse.success(spotify.status()))

                BridgeContract.Methods.CONNECT_SPOTIFY -> result.success(connectSpotify())

                BridgeContract.Methods.DISCONNECT_SPOTIFY -> onNetwork(result) {
                    spotify.signOut()
                    BridgeResponse.success(spotify.status())
                }

                BridgeContract.Methods.GET_SPOTIFY_PLAYLISTS -> onNetwork(result) {
                    val page = spotify.playlists()
                    BridgeResponse.success(
                        mapOf("playlists" to page.editable.map { it.toMap() }, "hiddenCount" to page.hiddenCount),
                    )
                }

                BridgeContract.Methods.CREATE_SPOTIFY_PLAYLIST -> {
                    val name = call.argument<String>("name")?.trim()?.takeIf { it.isNotEmpty() && it.length <= 100 }
                        ?: return result.success(invalid("name"))
                    onNetwork(result) { BridgeResponse.success(spotify.createPlaylist(name).toMap()) }
                }

                BridgeContract.Methods.SET_DEFAULT_SPOTIFY_PLAYLIST -> {
                    val id = call.argument<String>("id") ?: return result.success(invalid("id"))
                    val name = call.argument<String>("name") ?: return result.success(invalid("name"))
                    spotify.setDefaultPlaylist(id, name)
                    result.success(BridgeResponse.success(spotify.status()))
                }

                BridgeContract.Methods.FIND_SPOTIFY_TRACK -> {
                    val songId = call.longArgument("songId") ?: return result.success(invalid("songId"))
                    onNetwork(result) { BridgeResponse.success(spotify.findTrack(songId)) }
                }

                BridgeContract.Methods.ADD_TO_SPOTIFY_PLAYLIST -> {
                    val songId = call.longArgument("songId") ?: return result.success(invalid("songId"))
                    val playlistId = call.argument<String>("playlistId") ?: return result.success(invalid("playlistId"))
                    onNetwork(result) {
                        val added = spotify.addSong(
                            songId,
                            playlistId,
                            call.argument<String>("playlistName"),
                            call.argument<String>("trackId"),
                        )
                        BridgeResponse.success(mapOf("result" to added.wire))
                    }
                }

                BridgeContract.Methods.GET_SPOTIFY_SYNC_STATUS -> {
                    val songId = call.longArgument("songId") ?: return result.success(invalid("songId"))
                    onDatabase(result) { BridgeResponse.success(mapOf("items" to spotify.syncStatusForSong(songId))) }
                }

                BridgeContract.Methods.RETRY_SPOTIFY_SYNC -> onNetwork(result) {
                    BridgeResponse.success(mapOf("retried" to spotify.retryFailed(), "updated" to spotify.refreshVersions()))
                }

                BridgeContract.Methods.STOP_LISTENING -> {
                    SonoraRecognitionService.stop(context)
                    result.success(BridgeResponse.success())
                }

                BridgeContract.Methods.REQUEST_PERMISSIONS -> requestPermissions(result)

                BridgeContract.Methods.RECOGNIZE_ONCE ->
                    if (PrivacyConsent.isAccepted(context)) recognizeOnce(result) else result.success(consentRequired())

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

    /** Runs a Spotify call on the network thread; Spotify errors keep their codes. */
    private fun onNetwork(result: MethodChannel.Result, block: () -> Map<String, Any?>) {
        networkExecutor.execute {
            val response = try {
                block()
            } catch (e: SpotifyException) {
                BridgeResponse.failure(e.code, e.message ?: "Spotify error.")
            } catch (e: Exception) {
                Log.e(TAG, "Spotify operation failed", e)
                BridgeResponse.failure(BridgeErrorCode.INTERNAL_ERROR, "Spotify operation failed.")
            }
            mainHandler.post { result.success(response) }
        }
    }

    /** Opens Spotify's sign-in page in the browser; the redirect returns to MainActivity. */
    private fun connectSpotify(): Map<String, Any?> = try {
        val url = spotify.beginSignIn()
        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        BridgeResponse.success()
    } catch (e: SpotifyException) {
        BridgeResponse.failure(e.code, e.message ?: "Spotify isn't configured.")
    } catch (e: ActivityNotFoundException) {
        BridgeResponse.failure(NO_APP, "No browser available for Spotify sign-in.")
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
        // The disclosure must come before Android's permission prompt.
        if (!PrivacyConsent.isAccepted(context)) return result.success(consentRequired())
        permissions.requestPermissions { statuses -> result.success(BridgeResponse.success(statuses)) }
    }

    /** Service state plus things only the app needs: interruption and battery setting. */
    private fun listeningStatus(): Map<String, Any?> = ServiceStateManager.snapshot.toMap() + mapOf(
        "interrupted" to ListeningRecovery.wasInterrupted(context),
        "batteryUnrestricted" to ListeningRecovery.batteryUnrestricted(context),
    )

    /** App info, where One UI keeps the Battery (Unrestricted / Optimised / Restricted) setting. */
    private fun openBatterySettings(): Map<String, Any?> = try {
        context.startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", context.packageName, null))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
        BridgeResponse.success()
    } catch (e: ActivityNotFoundException) {
        BridgeResponse.failure(NO_APP, "Couldn't open settings.")
    }

    /** Android 13+ asks the user to add the tile; older versions need manual editing of Quick Settings. */
    /** Which ACRCloud keys are in use. Never includes the key or secret. */
    private fun recognitionProvider(): Map<String, Any?> {
        val credentials = AcrCloudCredentials.get(context)
        return mapOf(
            "sdkAvailable" to RecognitionEngineFactory.SDK_AVAILABLE,
            "source" to credentials.source()?.wire,
            "host" to credentials.current()?.host,
        )
    }

    private fun requestAddTile(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(BridgeResponse.success(mapOf("result" to "unsupported")))
            return
        }
        val statusBar = context.getSystemService(StatusBarManager::class.java)
        statusBar.requestAddTileService(
            ComponentName(context, ListeningTileService::class.java),
            "Sonora",
            Icon.createWithResource(context, R.drawable.ic_stat_sonora),
            { mainHandler.post(it) },
        ) { code ->
            val outcome = when (code) {
                StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ADDED -> "added"
                StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ALREADY_ADDED -> "already_added"
                StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_NOT_ADDED -> "not_added"
                else -> "unavailable"
            }
            result.success(BridgeResponse.success(mapOf("result" to outcome)))
        }
    }

    private fun consentRequired() = BridgeResponse.failure(
        PrivacyConsent.CONSENT_REQUIRED,
        "Agree to how Sonora uses the microphone first.",
    )

    private fun startListening(): Map<String, Any?> = when {
        !PrivacyConsent.isAccepted(context) -> consentRequired()
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
                    mapOf(
                        "matched" to true,
                        "song" to outcome.song.toMap(),
                        "confident" to outcome.confident,
                        "elapsedMs" to elapsedMs,
                    ),
                )
                RecognitionOutcome.NoMatch, is RecognitionOutcome.Tentative -> BridgeResponse.success(
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
