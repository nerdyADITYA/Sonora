package dev.sonora.sonora.recognition

import android.content.Context
import dev.sonora.sonora.recognition.acrcloud.AcrCloudRecognitionEngine

/** Compiled when the ACRCloud SDK JAR is present in android/app/libs. */
object RecognitionEngineFactory {
    /** Whether this build contains a recognition SDK at all. */
    const val SDK_AVAILABLE = true

    fun create(context: Context): RecognitionEngine = AcrCloudRecognitionEngine(context)
}
