package dev.sonora.sonora.audio

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AudioLevelTest {

    /** 16-bit little-endian PCM of a constant sample value. */
    private fun constant(value: Short, samples: Int = 1_000) = ByteArray(samples * 2).also {
        for (i in 0 until samples) {
            it[i * 2] = (value.toInt() and 0xFF).toByte()
            it[i * 2 + 1] = (value.toInt() shr 8).toByte()
        }
    }

    @Test
    fun `all-zero audio is silent`() {
        assertTrue(AudioCaptureManager.isSilent(ByteArray(2_000)))
        assertEquals(-120.0, AudioCaptureManager.levelDbfs(ByteArray(2_000)), 0.0)
    }

    @Test
    fun `audible audio is not silent`() {
        assertFalse(AudioCaptureManager.isSilent(constant(500)))
    }

    @Test
    fun `full scale is about 0 dBFS and half scale about -6 dBFS`() {
        assertEquals(0.0, AudioCaptureManager.levelDbfs(constant(Short.MAX_VALUE)), 0.01)
        assertEquals(-6.02, AudioCaptureManager.levelDbfs(constant(16_384)), 0.05)
    }

    @Test
    fun `negative samples count by magnitude`() {
        assertEquals(
            AudioCaptureManager.levelDbfs(constant(1_000)),
            AudioCaptureManager.levelDbfs(constant(-1_000)),
            0.001,
        )
    }

    @Test
    fun `only the requested prefix is measured`() {
        val pcm = ByteArray(4_000)
        constant(8_000).copyInto(pcm, destinationOffset = 2_000)
        assertTrue(AudioCaptureManager.isSilent(pcm, length = 2_000))
        assertFalse(AudioCaptureManager.isSilent(pcm))
    }
}
