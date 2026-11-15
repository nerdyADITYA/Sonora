package dev.sonora.sonora.services

import android.content.Context
import android.os.PowerManager

/**
 * Notices when Android or One UI ended listening without the user stopping
 * it. Android doesn't allow restarting the microphone from the background,
 * so Sonora can only tell the user next time they open the app.
 */
object ListeningRecovery {
    private const val PREFS = "sonora_listening"
    private const val KEY_INTENDED = "listening_intended"

    fun markStarted(context: Context) = prefs(context).edit().putBoolean(KEY_INTENDED, true).apply()

    /** The user stopped listening, or dismissed the interruption notice. */
    fun markStopped(context: Context) = prefs(context).edit().putBoolean(KEY_INTENDED, false).apply()

    /** Listening was on, the user didn't stop it, and the service is gone. */
    fun wasInterrupted(context: Context): Boolean =
        prefs(context).getBoolean(KEY_INTENDED, false) && !ServiceStateManager.snapshot.listening

    /** Battery usage set to "Unrestricted", so One UI won't put Sonora to sleep. */
    fun batteryUnrestricted(context: Context): Boolean =
        context.getSystemService(PowerManager::class.java)?.isIgnoringBatteryOptimizations(context.packageName) ?: false

    fun powerSaveOn(context: Context): Boolean =
        context.getSystemService(PowerManager::class.java)?.isPowerSaveMode ?: false

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
