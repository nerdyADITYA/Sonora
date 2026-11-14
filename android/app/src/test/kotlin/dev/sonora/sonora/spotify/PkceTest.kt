package dev.sonora.sonora.spotify

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class PkceTest {

    @Test
    fun `challenge matches the RFC 7636 appendix B test vector`() {
        assertEquals(
            "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
            Pkce.challenge("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"),
        )
    }

    @Test
    fun `base64url has no padding and uses url-safe characters`() {
        assertEquals("", Pkce.base64Url(ByteArray(0)))
        assertEquals("Zg", Pkce.base64Url("f".toByteArray()))
        assertEquals("Zm8", Pkce.base64Url("fo".toByteArray()))
        assertEquals("Zm9v", Pkce.base64Url("foo".toByteArray()))
        assertEquals("-_8", Pkce.base64Url(byteArrayOf(0xFB.toByte(), 0xFF.toByte())))
    }

    @Test
    fun `verifiers are long, unreserved and random`() {
        val a = Pkce.newVerifier()
        val b = Pkce.newVerifier()
        assertEquals(64, a.length)
        assertTrue(a.all { it.isLetterOrDigit() || it == '-' || it == '_' })
        assertNotEquals(a, b)
    }

    @Test
    fun `authorize url carries PKCE, state and scopes`() {
        val url = SpotifyAuth.authorizeUrl("client123", "sonora://spotify-callback", "a b", "st8", "chal")
        assertEquals(
            "https://accounts.spotify.com/authorize?client_id=client123&response_type=code" +
                "&redirect_uri=sonora%3A%2F%2Fspotify-callback&code_challenge_method=S256" +
                "&code_challenge=chal&state=st8&scope=a+b",
            url,
        )
    }
}
