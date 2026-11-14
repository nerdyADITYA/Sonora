package dev.sonora.sonora

import dev.sonora.sonora.bridge.SonoraEventChannel
import dev.sonora.sonora.bridge.SonoraMethodChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Hosts the Flutter UI and wires up the Flutter <-> Kotlin bridge.
 *
 * The activity only owns channel registration. Long-lived work (audio capture,
 * recognition, the foreground service) must not depend on this activity, so
 * those components will publish through [dev.sonora.sonora.bridge.SonoraEvents]
 * rather than holding a reference to the Flutter engine.
 */
class MainActivity : FlutterActivity() {

    private var methodChannel: SonoraMethodChannel? = null
    private var eventChannel: SonoraEventChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        methodChannel = SonoraMethodChannel(applicationContext, messenger).also { it.register() }
        eventChannel = SonoraEventChannel(messenger).also { it.register() }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        methodChannel?.unregister()
        eventChannel?.unregister()
        methodChannel = null
        eventChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
