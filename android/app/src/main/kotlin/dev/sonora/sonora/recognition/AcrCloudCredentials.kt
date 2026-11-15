package dev.sonora.sonora.recognition

import android.content.Context
import dev.sonora.sonora.BuildConfig
import dev.sonora.sonora.security.SecureTokenStorage

/**
 * The ACRCloud project Sonora recognises with.
 *
 * Public builds ship without a key: each user enters their own project's
 * host, access key and secret in Settings. They are stored encrypted with an
 * Android Keystore key, used only natively, and never returned to Flutter.
 * A developer build can instead bake keys in from android/local.properties;
 * keys entered in Settings take priority.
 */
class AcrCloudCredentials private constructor(context: Context) {

    data class Keys(val host: String, val accessKey: String, val accessSecret: String)

    enum class Source(val wire: String) { SETTINGS("settings"), BUILD("build") }

    private val store = SecureTokenStorage(context, prefsName = PREFS)

    /** The keys to use now, or null when none are set. */
    fun current(): Keys? = fromSettings() ?: fromBuild()

    fun source(): Source? = when {
        fromSettings() != null -> Source.SETTINGS
        fromBuild() != null -> Source.BUILD
        else -> null
    }

    /** Validates and stores keys entered by the user. Throws [IllegalArgumentException] with a readable message. */
    fun save(host: String?, accessKey: String?, accessSecret: String?) {
        val keys = validate(host, accessKey, accessSecret)
        store.put(HOST, keys.host)
        store.put(ACCESS_KEY, keys.accessKey)
        store.put(ACCESS_SECRET, keys.accessSecret)
    }

    fun clear() = store.clear()

    private fun fromSettings(): Keys? {
        val host = store.get(HOST) ?: return null
        val key = store.get(ACCESS_KEY) ?: return null
        val secret = store.get(ACCESS_SECRET) ?: return null
        return Keys(host, key, secret)
    }

    private fun fromBuild(): Keys? =
        Keys(BuildConfig.ACRCLOUD_HOST, BuildConfig.ACRCLOUD_ACCESS_KEY, BuildConfig.ACRCLOUD_ACCESS_SECRET)
            .takeIf { it.host.isNotBlank() && it.accessKey.isNotBlank() && it.accessSecret.isNotBlank() }

    companion object {
        private const val PREFS = "sonora_provider_keys"
        private const val HOST = "acrcloud_host"
        private const val ACCESS_KEY = "acrcloud_access_key"
        private const val ACCESS_SECRET = "acrcloud_access_secret"

        /** The project host as shown in the ACRCloud console, e.g. identify-eu-west-1.acrcloud.com. */
        private val HOST_PATTERN = Regex("^[a-z0-9-]+(\\.[a-z0-9-]+)*\\.acrcloud\\.(com|cn)$")

        @Volatile
        private var instance: AcrCloudCredentials? = null

        fun get(context: Context): AcrCloudCredentials =
            instance ?: synchronized(this) {
                instance ?: AcrCloudCredentials(context.applicationContext).also { instance = it }
            }

        /** Trims pasted values and accepts a host with or without https:// and a trailing slash. */
        fun validate(host: String?, accessKey: String?, accessSecret: String?): Keys {
            val cleanHost = host.orEmpty().trim().lowercase()
                .removePrefix("https://").removePrefix("http://").trimEnd('/')
            require(HOST_PATTERN.matches(cleanHost)) {
                "Enter the host from your ACRCloud project, like identify-eu-west-1.acrcloud.com."
            }
            val key = accessKey.orEmpty().trim()
            val secret = accessSecret.orEmpty().trim()
            require(key.isNotEmpty()) { "Enter the access key." }
            require(secret.isNotEmpty()) { "Enter the access secret." }
            require(key.none { it.isWhitespace() } && secret.none { it.isWhitespace() }) {
                "Keys can't contain spaces. Copy them again from the ACRCloud console."
            }
            return Keys(cleanHost, key, secret)
        }
    }
}
