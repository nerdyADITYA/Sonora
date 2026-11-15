package dev.sonora.sonora.recognition

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class AcrCloudCredentialsTest {

    @Test
    fun `pasted hosts and keys are cleaned up`() {
        val keys = AcrCloudCredentials.validate(" https://Identify-EU-West-1.acrcloud.com/ ", " abc123 ", "s3cr3t\n")
        assertEquals("identify-eu-west-1.acrcloud.com", keys.host)
        assertEquals("abc123", keys.accessKey)
        assertEquals("s3cr3t", keys.accessSecret)
    }

    @Test
    fun `only ACRCloud hosts are accepted`() {
        assertThrows(IllegalArgumentException::class.java) {
            AcrCloudCredentials.validate("example.com", "a", "b")
        }
        assertThrows(IllegalArgumentException::class.java) {
            AcrCloudCredentials.validate("acrcloud.com.evil.net", "a", "b")
        }
        AcrCloudCredentials.validate("identify-cn-north-1.acrcloud.cn", "a", "b")
    }

    @Test
    fun `missing or split keys are refused`() {
        assertThrows(IllegalArgumentException::class.java) {
            AcrCloudCredentials.validate("identify-eu-west-1.acrcloud.com", "", "b")
        }
        assertThrows(IllegalArgumentException::class.java) {
            AcrCloudCredentials.validate("identify-eu-west-1.acrcloud.com", "a", null)
        }
        assertThrows(IllegalArgumentException::class.java) {
            AcrCloudCredentials.validate("identify-eu-west-1.acrcloud.com", "a b", "c")
        }
    }
}
