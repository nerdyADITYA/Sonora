package dev.sonora.sonora

import android.Manifest
import android.content.pm.PackageManager
import dev.sonora.sonora.bridge.PermissionRequester
import dev.sonora.sonora.bridge.SonoraEventChannel
import dev.sonora.sonora.bridge.SonoraMethodChannel
import dev.sonora.sonora.recognition.RecognitionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Hosts the Flutter UI and wires up the Flutter <-> Kotlin bridge.
 *
 * Long-lived work must not depend on this activity. Native components publish
 * through [dev.sonora.sonora.bridge.SonoraEvents]. The activity's extra job
 * is runtime permission prompts, which need an activity.
 */
class MainActivity : FlutterActivity(), PermissionRequester {

    private var methodChannel: SonoraMethodChannel? = null
    private var eventChannel: SonoraEventChannel? = null
    private var recognition: RecognitionManager? = null
    private var pendingMicrophoneResult: ((String) -> Unit)? = null

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

    override fun requestMicrophone(onResult: (String) -> Unit) {
        if (pendingMicrophoneResult != null) {
            onResult(DENIED) // A prompt is already showing.
            return
        }
        pendingMicrophoneResult = onResult
        requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), REQUEST_MICROPHONE)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_MICROPHONE) return
        val callback = pendingMicrophoneResult ?: return
        pendingMicrophoneResult = null

        val status = when {
            grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED -> GRANTED
            // After a denial Android stops showing the prompt; the user must use Settings.
            !shouldShowRequestPermissionRationale(Manifest.permission.RECORD_AUDIO) -> PERMANENTLY_DENIED
            else -> DENIED
        }
        callback(status)
    }

    private companion object {
        const val REQUEST_MICROPHONE = 4101
        const val GRANTED = "granted"
        const val DENIED = "denied"
        const val PERMANENTLY_DENIED = "permanently_denied"
    }
}
