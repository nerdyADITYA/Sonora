package dev.sonora.sonora.recognition

import android.content.Context
import dev.sonora.sonora.recognition.acrcloud.AcrCloudRecognitionEngine

/** Compiled when the ACRCloud SDK JAR is present in android/app/libs. */
object RecognitionEngineFactory {
    fun create(context: Context): RecognitionEngine = AcrCloudRecognitionEngine(context)
}
