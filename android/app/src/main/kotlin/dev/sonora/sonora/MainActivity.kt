package dev.sonora.sonora

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import dev.sonora.sonora.bridge.LaunchRequests
import dev.sonora.sonora.bridge.PermissionRequester
import dev.sonora.sonora.bridge.SonoraEventChannel
import dev.sonora.sonora.bridge.SonoraMethodChannel
import dev.sonora.sonora.recognition.RecognitionManager
import dev.sonora.sonora.spotify.SpotifyException
import dev.sonora.sonora.spotify.SpotifyManager
import java.util.concurrent.Executors
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Hosts the Flutter UI and wires up the Flutter <-> Kotlin bridge.
 *
 * Long-lived work (the listening service) must not depend on this activity.
 * Native components publish through [dev.sonora.sonora.bridge.SonoraEvents].
 * The activity's extra job is runtime permission prompts, which need an activity.
 */
class MainActivity : FlutterActivity(), PermissionRequester {

    private var methodChannel: SonoraMethodChannel? = null
    private var eventChannel: SonoraEventChannel? = null
    private var recognition: RecognitionManager? = null
    private var pendingPermissionResult: ((Map<String, String>) -> Unit)? = null
    private val signInExecutor = Executors.newSingleThreadExecutor()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleSpotifyRedirect(intent)
        handleOpenSong(intent)
    }

    // launchMode is singleTop, so the Spotify redirect usually arrives here.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleSpotifyRedirect(intent)
        handleOpenSong(intent)
    }

    /** The listening notification opens a specific song. */
    private fun handleOpenSong(intent: Intent?) {
        val songId = intent?.getLongExtra(EXTRA_SONG_ID, -1L) ?: return
        if (songId < 0) return
        intent.removeExtra(EXTRA_SONG_ID) // Not again after a configuration change.
        LaunchRequests.offer(songId)
    }

    /** Finishes Spotify sign-in off the main thread; the result reaches Flutter as `spotify_status`. */
    private fun handleSpotifyRedirect(intent: Intent?) {
        val uri = intent?.data ?: return
        if (!SpotifyManager.isRedirect(uri)) return
        setIntent(Intent(intent).setData(null)) // Don't run it again after a configuration change.
        signInExecutor.execute {
            try {
                SpotifyManager.get(applicationContext).completeSignIn(uri)
            } catch (e: SpotifyException) {
                // Already published as a spotify_status event carrying the error code.
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val manager = RecognitionManager(applicationContext).also { recognition = it }
        methodChannel = SonoraMethodChannel(applicationContext, messenger, manager, this).also { it.register() }
        eventChannel = SonoraEventChannel(messenger).also { it.register() }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        methodChannel?.unregister()
        eventChannel?.unregister()
        recognition?.release()
        methodChannel = null
        eventChannel = null
        recognition = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private val requestedPermissions: List<String>
        get() = buildList {
            add(Manifest.permission.RECORD_AUDIO)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) add(Manifest.permission.POST_NOTIFICATIONS)
        }

    override fun requestPermissions(onResult: (Map<String, String>) -> Unit) {
        val missing = requestedPermissions.filter { checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED }
        if (missing.isEmpty() || pendingPermissionResult != null) {
            onResult(currentStatuses())
            return
        }
        pendingPermissionResult = onResult
        requestPermissions(missing.toTypedArray(), REQUEST_PERMISSIONS)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_PERMISSIONS) return
        val callback = pendingPermissionResult ?: return
        pendingPermissionResult = null
        callback(currentStatuses())
    }

    private fun currentStatuses(): Map<String, String> = mapOf(
        "microphone" to statusOf(Manifest.permission.RECORD_AUDIO),
        "notifications" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            statusOf(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            GRANTED // Granted at install before Android 13.
        },
    )

    private fun statusOf(permission: String): String = when {
        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED -> GRANTED
        // After a denial Android stops showing the prompt; the user must use Settings.
        !shouldShowRequestPermissionRationale(permission) -> PERMANENTLY_DENIED
        else -> DENIED
    }

    companion object {
        const val EXTRA_SONG_ID = "dev.sonora.sonora.extra.OPEN_SONG_ID"
        private const val REQUEST_PERMISSIONS = 4101
        private const val GRANTED = "granted"
        private const val DENIED = "denied"
        private const val PERMANENTLY_DENIED = "permanently_denied"
    }
}
