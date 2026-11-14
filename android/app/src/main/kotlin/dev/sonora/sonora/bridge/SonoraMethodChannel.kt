package dev.sonora.sonora.bridge

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import dev.sonora.sonora.recognition.RecognitionManager
import dev.sonora.sonora.recognition.RecognitionOutcome
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Asks the user for runtime permissions. Implemented by the hosting activity. */
fun interface PermissionRequester {
    /** [onResult] receives "granted", "denied" or "permanently_denied". */
    fun requestMicrophone(onResult: (String) -> Unit)
}

/** Handles request/response calls from Flutter on [BridgeContract.CONTROL_CHANNEL]. */
class SonoraMethodChannel(
    private val context: Context,
    messenger: BinaryMessenger,
    private val recognition: RecognitionManager,
    private val permissions: PermissionRequester,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, BridgeContract.CONTROL_CHANNEL)

    fun register() = channel.setMethodCallHandler(this)

    fun unregister() = channel.setMethodCallHandler(null)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                BridgeContract.Methods.GET_PLATFORM_INFO ->
                    result.success(BridgeResponse.success(platformInfo()))

                BridgeContract.Methods.GET_LISTENING_STATUS ->
                    // Continuous listening arrives in Phase 3.
                    result.success(BridgeResponse.success(mapOf("listening" to false, "available" to false)))

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

    private fun requestPermissions(result: MethodChannel.Result) {
        if (recognition.hasMicrophonePermission) {
            result.success(BridgeResponse.success(mapOf("microphone" to "granted")))
            return
        }
        permissions.requestMicrophone { status ->
            result.success(BridgeResponse.success(mapOf("microphone" to status)))
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
    }
}
