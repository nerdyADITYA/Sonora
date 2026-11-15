package dev.sonora.sonora.recognition.acrcloud

import android.content.Context
import android.util.Log
import com.acrcloud.rec.ACRCloudClient
import com.acrcloud.rec.ACRCloudConfig
import com.acrcloud.rec.ACRCloudResult
import com.acrcloud.rec.IACRCloudListener
import dev.sonora.sonora.BuildConfig
import dev.sonora.sonora.recognition.RecognitionEngine
import dev.sonora.sonora.recognition.RecognitionErrorCodes
import dev.sonora.sonora.recognition.RecognitionOutcome

/**
 * ACRCloud engine. The fingerprint is computed on the device and only the
 * fingerprint is sent to ACRCloud. Raw audio never leaves the phone.
 */
class AcrCloudRecognitionEngine(private val context: Context) : RecognitionEngine {

    override val providerName: String = AcrCloudResponseParser.PROVIDER

    private var client: ACRCloudClient? = null

    override fun recognize(pcm: ByteArray, sampleRate: Int, channels: Int): RecognitionOutcome {
        if (BuildConfig.ACRCLOUD_HOST.isBlank() ||
            BuildConfig.ACRCLOUD_ACCESS_KEY.isBlank() ||
            BuildConfig.ACRCLOUD_ACCESS_SECRET.isBlank()
        ) {
            return RecognitionOutcome.Failure(
                RecognitionErrorCodes.NOT_CONFIGURED,
                "ACRCloud credentials are missing from android/local.properties.",
            )
        }

        return try {
            val fingerprint = ACRCloudClient.createClientFingerprint(pcm, pcm.size, sampleRate, channels)
            if (fingerprint == null || fingerprint.isEmpty()) return RecognitionOutcome.NoMatch

            val json = requireClient().recognizeFingerprint(
                fingerprint,
                fingerprint.size,
                ACRCloudConfig.RecognizerType.AUDIO,
                HashMap(),
            )
            AcrCloudResponseParser.parse(json)
        } catch (e: UnsatisfiedLinkError) {
            // Native engine missing for this ABI (only arm64-v8a is bundled).
            Log.e(TAG, "ACRCloud native library unavailable", e)
            RecognitionOutcome.Failure(RecognitionErrorCodes.PROVIDER_UNAVAILABLE, "ACRCloud engine not available on this device.")
        } catch (e: Exception) {
            Log.e(TAG, "ACRCloud recognition failed", e)
            RecognitionOutcome.Failure(RecognitionErrorCodes.PROVIDER_ERROR, "ACRCloud recognition failed.")
        }
    }

    private fun requireClient(): ACRCloudClient {
        client?.let { return it }
        val config = ACRCloudConfig().apply {
            context = this@AcrCloudRecognitionEngine.context.applicationContext
            host = BuildConfig.ACRCLOUD_HOST
            accessKey = BuildConfig.ACRCLOUD_ACCESS_KEY
            accessSecret = BuildConfig.ACRCLOUD_ACCESS_SECRET
            // Sonora owns the microphone. By default initWithConfig() starts an
            // 8 kHz "pre-record" that holds the mic open alongside Sonora's own
            // capture and degrades it, so the SDK gets no recorder at all.
            recorderType = ACRCloudConfig.RecorderType.USER
            recorderConfig.reservedRecordBufferMS = 0
            recorderConfig.isVolumeCallback = false
            acrcloudListener = object : IACRCloudListener {
                override fun onResult(result: ACRCloudResult?) = Unit
                override fun onVolumeChanged(volume: Double) = Unit
            }
        }
        val created = ACRCloudClient()
        check(created.initWithConfig(config)) { "ACRCloud client failed to initialise." }
        client = created
        return created
    }

    override fun release() {
        client?.release()
        client = null
    }

    private companion object {
        const val TAG = "AcrCloudEngine"
    }
}
