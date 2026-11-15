package dev.sonora.sonora.recognition

import android.content.Context

/**
 * Compiled when the ACRCloud SDK is absent (fresh clones, CI). The app still
 * builds and runs; recognition reports PROVIDER_UNAVAILABLE.
 */
object RecognitionEngineFactory {
    /** Whether this build contains a recognition SDK at all. */
    const val SDK_AVAILABLE = false

    fun create(context: Context): RecognitionEngine = object : RecognitionEngine {
        override val providerName = "none"

        override fun recognize(pcm: ByteArray, sampleRate: Int, channels: Int) =
            RecognitionOutcome.Failure(
                RecognitionErrorCodes.PROVIDER_UNAVAILABLE,
                "No recognition SDK in this build. See docs/RECOGNITION_FEASIBILITY.md.",
            )

        override fun release() = Unit
    }
}
