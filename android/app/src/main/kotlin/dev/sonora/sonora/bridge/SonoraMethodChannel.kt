package dev.sonora.sonora.bridge

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Handles request/response calls from Flutter on [BridgeContract.CONTROL_CHANNEL]. */
class SonoraMethodChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, BridgeContract.CONTROL_CHANNEL)

    fun register() = channel.setMethodCallHandler(this)

    fun unregister() = channel.setMethodCallHandler(null)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val response = try {
            when (call.method) {
                BridgeContract.Methods.GET_PLATFORM_INFO ->
                    BridgeResponse.success(platformInfo())

                BridgeContract.Methods.GET_LISTENING_STATUS ->
                    // No audio capture exists yet (Phase 3). Report that honestly.
                    BridgeResponse.success(mapOf("listening" to false, "available" to false))

                in BridgeContract.Methods.PLANNED ->
                    BridgeResponse.failure(
                        BridgeErrorCode.NOT_IMPLEMENTED,
                        "${call.method} is not available in this version.",
                    )

                else -> null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to handle ${call.method}", e)
            BridgeResponse.failure(BridgeErrorCode.INTERNAL_ERROR, "Native error while handling ${call.method}.")
        }

        if (response == null) result.notImplemented() else result.success(response)
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
