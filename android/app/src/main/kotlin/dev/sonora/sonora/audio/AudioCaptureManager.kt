package dev.sonora.sonora.audio

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import kotlin.math.abs

/** Thrown when the microphone can't be used. [code] is a bridge error code. */
class AudioCaptureException(val code: String, message: String) : Exception(message)

/**
 * Captures a short PCM sample from the microphone into memory.
 *
 * Nothing is written to disk. The caller owns the returned buffer and must
 * drop it once recognition finishes.
 */
class AudioCaptureManager(private val context: Context) {

    @Volatile
    private var cancelled = false

    fun hasPermission(): Boolean =
        context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

    fun cancel() {
        cancelled = true
    }

    /** Blocks for about [durationMs]. Call from a worker thread. */
    @SuppressLint("MissingPermission") // Checked by hasPermission() below.
    fun capture(durationMs: Int = AudioConfiguration.CAPTURE_DURATION_MS): ByteArray {
        if (!hasPermission()) {
            throw AudioCaptureException(PERMISSION_REQUIRED, "Microphone permission not granted.")
        }
        cancelled = false

        val minBuffer = AudioRecord.getMinBufferSize(
            AudioConfiguration.SAMPLE_RATE_HZ,
            AudioConfiguration.CHANNEL_MASK,
            AudioConfiguration.ENCODING,
        )
        if (minBuffer <= 0) throw AudioCaptureException(MICROPHONE_UNAVAILABLE, "Unsupported audio format.")

        val record = try {
            AudioRecord(
                audioSource(),
                AudioConfiguration.SAMPLE_RATE_HZ,
                AudioConfiguration.CHANNEL_MASK,
                AudioConfiguration.ENCODING,
                minBuffer * 4,
            )
        } catch (e: Exception) {
            throw AudioCaptureException(MICROPHONE_UNAVAILABLE, "Could not open the microphone.")
        }

        try {
            if (record.state != AudioRecord.STATE_INITIALIZED) {
                throw AudioCaptureException(MICROPHONE_UNAVAILABLE, "Microphone failed to initialise.")
            }
            record.startRecording()
            if (record.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
                throw AudioCaptureException(MICROPHONE_UNAVAILABLE, "Microphone is in use by another app.")
            }

            val pcm = ByteArray(AudioConfiguration.bytesFor(durationMs))
            var offset = 0
            while (offset < pcm.size && !cancelled) {
                val read = record.read(pcm, offset, minOf(minBuffer, pcm.size - offset))
                if (read < 0) throw AudioCaptureException(MICROPHONE_UNAVAILABLE, "Microphone read failed ($read).")
                offset += read
            }
            if (cancelled) throw AudioCaptureException(CANCELLED, "Recognition cancelled.")

            // With the system microphone privacy toggle on, Android delivers pure silence.
            if (isSilent(pcm)) throw AudioCaptureException(MICROPHONE_SILENT, "Microphone returned only silence.")
            return pcm
        } finally {
            try {
                if (record.recordingState == AudioRecord.RECORDSTATE_RECORDING) record.stop()
            } catch (e: IllegalStateException) {
                Log.w(TAG, "stop() failed", e)
            }
            record.release()
        }
    }

    /** UNPROCESSED skips voice-oriented noise suppression that degrades music, when the device supports it. */
    private fun audioSource(): Int {
        val audioManager = context.getSystemService(AudioManager::class.java)
        val unprocessed = audioManager?.getProperty(AudioManager.PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED)
        return if (unprocessed == "true") MediaRecorder.AudioSource.UNPROCESSED else MediaRecorder.AudioSource.MIC
    }

    private fun isSilent(pcm: ByteArray): Boolean {
        var i = 0
        while (i + 1 < pcm.size) {
            val sample = (pcm[i].toInt() and 0xFF) or (pcm[i + 1].toInt() shl 8)
            if (abs(sample.toShort().toInt()) > SILENCE_THRESHOLD) return false
            i += 2
        }
        return true
    }

    companion object {
        private const val TAG = "AudioCaptureManager"
        private const val SILENCE_THRESHOLD = 4

        const val PERMISSION_REQUIRED = "PERMISSION_REQUIRED"
        const val MICROPHONE_UNAVAILABLE = "MICROPHONE_UNAVAILABLE"
        const val MICROPHONE_SILENT = "MICROPHONE_SILENT"
        const val CANCELLED = "CANCELLED"
    }
}
