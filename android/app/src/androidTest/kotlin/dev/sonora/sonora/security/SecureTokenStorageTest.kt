package dev.sonora.sonora.security

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith

/** Encrypted storage on a real Keystore. Uses test-only files, never the app's own. */
@RunWith(AndroidJUnit4::class)
class SecureTokenStorageTest {

    private val context: Context = InstrumentationRegistry.getInstrumentation().targetContext
    private val tokens = SecureTokenStorage(context, prefsName = "test_secure_a")
    private val keys = SecureTokenStorage(context, prefsName = "test_secure_b")

    @After
    fun cleanUp() {
        tokens.clear()
        keys.clear()
    }

    @Test
    fun valuesRoundTripAndAreNotStoredInPlainText() {
        tokens.put("token", "very-secret-value")
        assertEquals("very-secret-value", tokens.get("token"))

        val raw = context.getSharedPreferences("test_secure_a", Context.MODE_PRIVATE).getString("token", null)!!
        assertFalse(raw.contains("very-secret-value"))
    }

    @Test
    fun clearingOneStoreLeavesTheOthers() {
        // Spotify sign-out clears its store; ACRCloud keys live in another.
        tokens.put("refresh", "r")
        keys.put("acrcloud_access_secret", "s")
        tokens.clear()
        assertNull(tokens.get("refresh"))
        assertEquals("s", keys.get("acrcloud_access_secret"))
    }

    @Test
    fun corruptValuesReadAsMissing() {
        context.getSharedPreferences("test_secure_a", Context.MODE_PRIVATE)
            .edit().putString("token", "not:valid").commit()
        assertNull(tokens.get("token"))
    }
}
