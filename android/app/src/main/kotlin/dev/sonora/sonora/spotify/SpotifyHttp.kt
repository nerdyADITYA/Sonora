package dev.sonora.sonora.spotify

import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

/** A Spotify failure with a stable bridge error [code]. */
class SpotifyException(val code: String, message: String, val httpStatus: Int? = null) : Exception(message)

object SpotifyErrorCodes {
    const val NOT_CONFIGURED = "SPOTIFY_NOT_CONFIGURED"
    const val NOT_CONNECTED = "SPOTIFY_NOT_CONNECTED"
    const val AUTH_FAILED = "SPOTIFY_AUTH_FAILED"
    const val AUTH_CANCELLED = "SPOTIFY_AUTH_CANCELLED"
    const val FORBIDDEN = "SPOTIFY_FORBIDDEN"
    const val RATE_LIMITED = "SPOTIFY_RATE_LIMITED"
    const val NETWORK = "NETWORK_UNAVAILABLE"
    const val NOT_FOUND = "SPOTIFY_TRACK_NOT_FOUND"
    const val NEEDS_MATCH = "SPOTIFY_NEEDS_MATCH"
    const val API_ERROR = "SPOTIFY_API_ERROR"
}

/** Minimal HTTPS JSON client on HttpURLConnection; no extra dependencies. Blocking. */
internal object SpotifyHttp {
    private const val TIMEOUT_MS = 10_000

    data class Response(val status: Int, val body: String) {
        fun json(): JSONObject = if (body.isBlank()) JSONObject() else JSONObject(body)
    }

    fun form(params: Map<String, String>): String =
        params.entries.joinToString("&") { (k, v) -> "${encode(k)}=${encode(v)}" }

    fun encode(value: String): String = URLEncoder.encode(value, "UTF-8")

    fun request(
        method: String,
        url: String,
        bearer: String? = null,
        jsonBody: JSONObject? = null,
        formBody: String? = null,
    ): Response {
        val connection = URL(url).openConnection() as HttpURLConnection
        try {
            connection.requestMethod = method
            connection.connectTimeout = TIMEOUT_MS
            connection.readTimeout = TIMEOUT_MS
            connection.setRequestProperty("Accept", "application/json")
            bearer?.let { connection.setRequestProperty("Authorization", "Bearer $it") }

            val payload = when {
                jsonBody != null -> {
                    connection.setRequestProperty("Content-Type", "application/json")
                    jsonBody.toString()
                }
                formBody != null -> {
                    connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")
                    formBody
                }
                else -> null
            }
            if (payload != null) {
                connection.doOutput = true
                connection.outputStream.use { it.write(payload.toByteArray(Charsets.UTF_8)) }
            }

            val status = connection.responseCode
            val stream = if (status in 200..299) connection.inputStream else connection.errorStream
            val body = stream?.bufferedReader()?.use { it.readText() } ?: ""
            return Response(status, body)
        } catch (e: IOException) {
            throw SpotifyException(SpotifyErrorCodes.NETWORK, "Couldn't reach Spotify.")
        } finally {
            connection.disconnect()
        }
    }
}
