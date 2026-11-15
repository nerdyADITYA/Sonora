package dev.sonora.sonora.privacy

import android.content.Context

/**
 * Whether the user agreed to the in-app disclosure of how Sonora uses the
 * microphone and what it sends to ACRCloud and Spotify (Google Play's
 * "Prominent Disclosure and Consent" requirement).
 *
 * Kept natively so every way into the microphone checks it: the app, the
 * Quick Settings tile and the background service. Bump [CURRENT_VERSION] when
 * the disclosure text changes materially, so everyone is asked again.
 */
object PrivacyConsent {
    const val CURRENT_VERSION = 1

    /** Bridge and service error code when the microphone is used before consent. */
    const val CONSENT_REQUIRED = "CONSENT_REQUIRED"

    private const val PREFS = "sonora_consent"
    private const val KEY_VERSION = "accepted_version"
    private const val KEY_AT = "accepted_at"

    fun isAccepted(context: Context): Boolean =
        isCurrent(prefs(context).getInt(KEY_VERSION, 0))

    /** True when [acceptedVersion] covers the disclosure shown today. */
    fun isCurrent(acceptedVersion: Int): Boolean = acceptedVersion >= CURRENT_VERSION

    fun accept(context: Context) {
        prefs(context).edit()
            .putInt(KEY_VERSION, CURRENT_VERSION)
            .putLong(KEY_AT, System.currentTimeMillis())
            .apply()
    }

    fun withdraw(context: Context) {
        prefs(context).edit().clear().apply()
    }

    fun toMap(context: Context): Map<String, Any?> = mapOf(
        "accepted" to isAccepted(context),
        "version" to CURRENT_VERSION,
    )

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
