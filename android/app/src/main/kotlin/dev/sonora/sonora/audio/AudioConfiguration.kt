package dev.sonora.sonora.audio

import android.media.AudioFormat

/** Capture format. ACRCloud resamples internally; 44.1 kHz is supported by every Android device. */
object AudioConfiguration {
    const val SAMPLE_RATE_HZ = 44_100
    const val CHANNEL_COUNT = 1
    const val CHANNEL_MASK = AudioFormat.CHANNEL_IN_MONO
    const val ENCODING = AudioFormat.ENCODING_PCM_16BIT
    const val BYTES_PER_SAMPLE = 2

    /** Length of one manual recognition sample. ACRCloud recommends roughly 10 s. */
    const val CAPTURE_DURATION_MS = 10_000

    fun bytesFor(durationMs: Int): Int =
        (SAMPLE_RATE_HZ.toLong() * CHANNEL_COUNT * BYTES_PER_SAMPLE * durationMs / 1000).toInt()
}
