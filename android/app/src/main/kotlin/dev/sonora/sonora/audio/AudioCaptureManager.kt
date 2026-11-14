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
import kotlin.math.log10
import kotlin.math.sqrt

/** Thrown when the microphone can't be used. [code] is a bridge error code. */
class AudioCaptureException(val code: String, message: String) : Exception(message)

/** Result of [AudioCaptureManager.captureGated]. */
sealed interface GatedCapture {
    /** Loud enough to be worth recognising. [pcm] must be wiped by the caller. */
    class Captured(val pcm: ByteArray, val levelDbfs: Double) : GatedCapture

    /** The probe was too quiet; nothing was kept. */
    data class TooQuiet(val levelDbfs: Double) : GatedCapture

    /** Pure digital silence: the privacy toggle is on or another app holds the mic. */
    data object Silent : GatedCapture
}

/**
 * Captures short PCM samples from the microphone into memory.
 *
 * Nothing is written to disk. The microphone is open only for the duration
 * of a capture call. Callers own the returned buffers and must wipe them.
 */
class AudioCaptureManager(private val context: Context) {

    @Volatile
    private var cancelled = false

    fun hasPermission(): Boolean =
        context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

    fun cancel() {
        cancelled = true
    }

    /** Manual capture of a fixed length. Blocks; call from a worker thread. */
    fun capture(durationMs: Int = AudioConfiguration.CAPTURE_DURATION_MS): ByteArray {
        cancelled = false
        return withRecorder { record, chunk ->
            val pcm = ByteArray(AudioConfiguration.bytesFor(durationMs))
            readFully(record, pcm, 0, pcm.size, chunk)
            if (isSilent(pcm)) {
                pcm.fill(0)
                throw AudioCaptureException(MICROPHONE_SILENT, "Microphone returned only silence.")
            }
            pcm
        }
    }

    /**
     * Ambient capture: records [probeMs] first and only continues to [totalMs]
     * when the probe is at least [minLevelDbfs]. Quiet rooms keep the
     * microphone on for the probe only, and never cost a recognition request.
     */
    fun captureGated(probeMs: Int, totalMs: Int, minLevelDbfs: Double): GatedCapture {
        cancelled = false
        return withRecorder { record, chunk ->
            val pcm = ByteArray(AudioConfiguration.bytesFor(totalMs))
            val probeBytes = AudioConfiguration.bytesFor(probeMs)
            readFully(record, pcm, 0, probeBytes, chunk)

            if (isSilent(pcm, probeBytes)) {
                pcm.fill(0)
                return@withRecorder GatedCapture.Silent
            }
            val probeLevel = levelDbfs(pcm, probeBytes)
            if (probeLevel < minLevelDbfs) {
                pcm.fill(0)
                return@withRecorder GatedCapture.TooQuiet(probeLevel)
            }

            readFully(record, pcm, probeBytes, pcm.size, chunk)
            GatedCapture.Captured(pcm, levelDbfs(pcm, pcm.size))
        }
    }

    @SuppressLint("MissingPermission") // Checked first.
    private fun <T> withRecorder(block: (AudioRecord, Int) -> T): T {
        if (!hasPermission()) {
            throw AudioCaptureException(PERMISSION_REQUIRED, "Microphone permission not granted.")
        }
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
            return block(record, minBuffer)
        } finally {
            try {
                if (record.recordingState == AudioRecord.RECORDSTATE_RECORDING) record.stop()
            } catch (e: IllegalStateException) {
                Log.w(TAG, "stop() failed", e)
            }
            record.release()
        }
    }

    private fun readFully(record: AudioRecord, pcm: ByteArray, from: Int, to: Int, chunk: Int) {
        var offset = from
        while (offset < to && !cancelled) {
            val read = record.read(pcm, offset, minOf(chunk, to - offset))
            if (read < 0) {
                pcm.fill(0)
                throw AudioCaptureException(MICROPHONE_UNAVAILABLE, "Microphone read failed ($read).")
            }
            offset += read
        }
        if (cancelled) {
            pcm.fill(0)
            throw AudioCaptureException(CANCELLED, "Capture cancelled.")
        }
    }

    /** UNPROCESSED skips voice-oriented noise suppression that degrades music, when the device supports it. */
    private fun audioSource(): Int {
        val audioManager = context.getSystemService(AudioManager::class.java)
        val unprocessed = audioManager?.getProperty(AudioManager.PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED)
        return if (unprocessed == "true") MediaRecorder.AudioSource.UNPROCESSED else MediaRecorder.AudioSource.MIC
    }

    companion object {
        private const val TAG = "AudioCaptureManager"
        private const val SILENCE_THRESHOLD = 4

        const val PERMISSION_REQUIRED = "PERMISSION_REQUIRED"
        const val MICROPHONE_UNAVAILABLE = "MICROPHONE_UNAVAILABLE"
        const val MICROPHONE_SILENT = "MICROPHONE_SILENT"
        const val CANCELLED = "CANCELLED"

        private fun sampleAt(pcm: ByteArray, i: Int): Int =
            ((pcm[i].toInt() and 0xFF) or (pcm[i + 1].toInt() shl 8)).toShort().toInt()

        fun isSilent(pcm: ByteArray, length: Int = pcm.size): Boolean {
            var i = 0
            while (i + 1 < length) {
                if (abs(sampleAt(pcm, i)) > SILENCE_THRESHOLD) return false
                i += 2
            }
            return true
        }

        /** RMS level in dBFS (0 = full scale, quieter is more negative). */
        fun levelDbfs(pcm: ByteArray, length: Int = pcm.size): Double {
            var sumSquares = 0.0
            var count = 0
            var i = 0
            while (i + 1 < length) {
                val s = sampleAt(pcm, i).toDouble()
                sumSquares += s * s
                count++
                i += 2
            }
            if (count == 0) return -120.0
            val rms = sqrt(sumSquares / count)
            return if (rms < 1.0) -120.0 else 20 * log10(rms / 32768.0)
        }
    }
}
