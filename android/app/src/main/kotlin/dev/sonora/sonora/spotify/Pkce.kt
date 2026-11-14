package dev.sonora.sonora.spotify

import java.security.MessageDigest
import java.security.SecureRandom

/** OAuth 2.0 PKCE helpers (RFC 7636). Pure Kotlin so they run in JVM tests. */
object Pkce {
    private val random = SecureRandom()
    private const val ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

    /** 64-character verifier from the unreserved character set. */
    fun newVerifier(length: Int = 64): String {
        require(length in 43..128)
        return buildString(length) { repeat(length) { append(ALPHABET[random.nextInt(ALPHABET.length)]) } }
    }

    /** Random value for the OAuth `state` parameter (CSRF protection). */
    fun newState(): String = newVerifier(43)

    /** S256 challenge: base64url(SHA-256(verifier)) without padding. */
    fun challenge(verifier: String): String =
        base64Url(MessageDigest.getInstance("SHA-256").digest(verifier.toByteArray(Charsets.US_ASCII)))

    /** Unpadded base64url. java.util.Base64 needs API 26, and Sonora supports 24. */
    fun base64Url(bytes: ByteArray): String {
        val out = StringBuilder((bytes.size * 4 + 2) / 3)
        var i = 0
        while (i < bytes.size) {
            val b0 = bytes[i].toInt() and 0xFF
            val b1 = if (i + 1 < bytes.size) bytes[i + 1].toInt() and 0xFF else 0
            val b2 = if (i + 2 < bytes.size) bytes[i + 2].toInt() and 0xFF else 0
            out.append(ALPHABET[b0 shr 2])
            out.append(ALPHABET[((b0 and 0x03) shl 4) or (b1 shr 4)])
            if (i + 1 < bytes.size) out.append(ALPHABET[((b1 and 0x0F) shl 2) or (b2 shr 6)])
            if (i + 2 < bytes.size) out.append(ALPHABET[b2 and 0x3F])
            i += 3
        }
        return out.toString()
    }
}
