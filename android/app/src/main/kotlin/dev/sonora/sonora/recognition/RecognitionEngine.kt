package dev.sonora.sonora.recognition

/**
 * A pluggable music recognition provider.
 *
 * Calls block and must run on a worker thread. ACRCloud has no streaming
 * session, so the engine matches one finished PCM sample at a time. A
 * streaming provider would add its own session API when one is introduced.
 */
interface RecognitionEngine {
    /** Short identifier stored with results, e.g. "acrcloud". */
    val providerName: String

    /** Matches 16-bit little-endian PCM. The engine must not retain [pcm]. */
    fun recognize(pcm: ByteArray, sampleRate: Int, channels: Int): RecognitionOutcome

    fun release()
}
