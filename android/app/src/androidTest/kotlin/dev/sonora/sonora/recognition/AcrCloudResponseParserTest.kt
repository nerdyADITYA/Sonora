package dev.sonora.sonora.recognition

import androidx.test.ext.junit.runners.AndroidJUnit4
import dev.sonora.sonora.recognition.acrcloud.AcrCloudResponseParser
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/** How ACRCloud's responses, including every failure it reports, reach the app. */
@RunWith(AndroidJUnit4::class)
class AcrCloudResponseParserTest {

    private fun status(code: Int) = """{"status":{"code":$code,"msg":"x"}}"""

    private fun failureCode(json: String?): String =
        (AcrCloudResponseParser.parse(json) as RecognitionOutcome.Failure).code

    @Test
    fun aConfidentMatchKeepsItsMetadata() {
        val json = """
            {"status":{"code":0},"metadata":{"music":[{
              "acrid":"abc","title":"Gulaab","score":100,"duration_ms":180000,"play_offset_ms":42000,
              "release_date":"2022-11-18","artists":[{"name":"Mitraz"}],"album":{"name":"Gulaab"},
              "external_ids":{"isrc":"INX123"},
              "external_metadata":{"spotify":{"track":{"id":"t1"},"album":{"id":"a1"}}}
            }]}}
        """.trimIndent()
        val match = AcrCloudResponseParser.parse(json, now = 7) as RecognitionOutcome.Match
        assertTrue(match.confident)
        with(match.song) {
            assertEquals("Gulaab", title)
            assertEquals("Mitraz", artist)
            assertEquals("INX123", isrc)
            assertEquals("t1", spotifyTrackId)
            assertEquals(180_000, durationMs)
            assertEquals(42_000, playOffsetMs)
            assertEquals(1.0, confidence!!, 0.0)
            assertEquals(7L, recognizedAt)
        }
    }

    @Test
    fun midScoresNeedConfirmationAndWeakOnesAreTentative() {
        fun music(score: Int) =
            """{"status":{"code":0},"metadata":{"music":[{"acrid":"a","title":"Dua","score":$score,"artists":[{"name":"X"}]}]}}"""
        assertFalse((AcrCloudResponseParser.parse(music(64)) as RecognitionOutcome.Match).confident)
        assertTrue(AcrCloudResponseParser.parse(music(43)) is RecognitionOutcome.Tentative)
        assertEquals(RecognitionOutcome.NoMatch, AcrCloudResponseParser.parse(music(20)))
    }

    @Test
    fun noResultAndUnfingerprintableAudioAreNoMatch() {
        assertEquals(RecognitionOutcome.NoMatch, AcrCloudResponseParser.parse(status(1001)))
        assertEquals(RecognitionOutcome.NoMatch, AcrCloudResponseParser.parse(status(2004)))
        assertEquals(RecognitionOutcome.NoMatch, AcrCloudResponseParser.parse("""{"status":{"code":0}}"""))
    }

    @Test
    fun providerFailuresMapToBridgeCodes() {
        assertEquals(RecognitionErrorCodes.NETWORK_UNAVAILABLE, failureCode(status(2005)))
        assertEquals(RecognitionErrorCodes.NETWORK_UNAVAILABLE, failureCode(status(3000)))
        assertEquals(RecognitionErrorCodes.INVALID_CREDENTIALS, failureCode(status(3001)))
        assertEquals(RecognitionErrorCodes.INVALID_CREDENTIALS, failureCode(status(3014)))
        assertEquals(RecognitionErrorCodes.QUOTA_EXCEEDED, failureCode(status(3003)))
        assertEquals(RecognitionErrorCodes.QUOTA_EXCEEDED, failureCode(status(3015)))
        assertEquals(RecognitionErrorCodes.PROVIDER_ERROR, failureCode(status(9999)))
    }

    @Test
    fun brokenResponsesAreErrorsNotCrashes() {
        assertEquals(RecognitionErrorCodes.PROVIDER_ERROR, failureCode(null))
        assertEquals(RecognitionErrorCodes.PROVIDER_ERROR, failureCode(""))
        assertEquals(RecognitionErrorCodes.PROVIDER_ERROR, failureCode("<html>502</html>"))
        assertEquals(RecognitionErrorCodes.PROVIDER_ERROR, failureCode("""{"no":"status"}"""))
    }
}
