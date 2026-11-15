package dev.sonora.sonora.privacy

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PrivacyConsentTest {

    @Test
    fun `no recorded agreement is not consent`() {
        assertFalse(PrivacyConsent.isCurrent(0))
    }

    @Test
    fun `agreeing to the current disclosure is consent`() {
        assertTrue(PrivacyConsent.isCurrent(PrivacyConsent.CURRENT_VERSION))
    }

    @Test
    fun `agreeing to an older disclosure must be asked again`() {
        assertFalse(PrivacyConsent.isCurrent(PrivacyConsent.CURRENT_VERSION - 1))
    }
}
