package dev.sonora.sonora.spotify

import android.content.Context
import android.net.Uri
import dev.sonora.sonora.BuildConfig
import dev.sonora.sonora.security.SecureTokenStorage

/**
 * Spotify sign-in with Authorization Code + PKCE (no client secret).
 *
 * The browser shows Spotify's own login and consent page; Sonora never sees
 * the password. Spotify redirects to `sonora://spotify-callback`, which
 * MainActivity hands to [completeSignIn]. Tokens stay in [SecureTokenStorage].
 */
class SpotifyAuth(context: Context) {

    private val store = SecureTokenStorage(context)

    val isConfigured: Boolean get() = CLIENT_ID.isNotBlank()

    val isSignedIn: Boolean get() = store.get(REFRESH_TOKEN) != null

    /** Creates a fresh PKCE verifier and state and returns the URL to open in the browser. */
    fun beginSignIn(): String {
        if (!isConfigured) throw SpotifyException(SpotifyErrorCodes.NOT_CONFIGURED, "Spotify Client ID missing.")
        val verifier = Pkce.newVerifier()
        val state = Pkce.newState()
        store.put(PENDING_VERIFIER, verifier)
        store.put(PENDING_STATE, state)
        return authorizeUrl(CLIENT_ID, REDIRECT_URI, SCOPES, state, Pkce.challenge(verifier))
    }

    /** Exchanges the redirect's code for tokens. Blocking; call off the main thread. */
    fun completeSignIn(redirect: Uri) {
        val expectedState = store.get(PENDING_STATE)
        val verifier = store.get(PENDING_VERIFIER)
        store.put(PENDING_STATE, null)
        store.put(PENDING_VERIFIER, null)

        redirect.getQueryParameter("error")?.let {
            throw SpotifyException(
                if (it == "access_denied") SpotifyErrorCodes.AUTH_CANCELLED else SpotifyErrorCodes.AUTH_FAILED,
                "Spotify sign-in did not complete ($it).",
            )
        }
        val code = redirect.getQueryParameter("code")
        if (code == null || verifier == null || expectedState == null || redirect.getQueryParameter("state") != expectedState) {
            // A missing or mismatched state means this redirect wasn't started by Sonora.
            throw SpotifyException(SpotifyErrorCodes.AUTH_FAILED, "Spotify sign-in could not be verified. Try again.")
        }

        val response = SpotifyHttp.request(
            "POST",
            TOKEN_URL,
            formBody = SpotifyHttp.form(
                mapOf(
                    "grant_type" to "authorization_code",
                    "code" to code,
                    "redirect_uri" to REDIRECT_URI,
                    "client_id" to CLIENT_ID,
                    "code_verifier" to verifier,
                ),
            ),
        )
        if (response.status != 200) {
            throw SpotifyException(SpotifyErrorCodes.AUTH_FAILED, "Spotify rejected the sign-in.", response.status)
        }
        saveTokens(response)
    }

    /** A valid access token, refreshed when it expires within a minute. Blocking. */
    @Synchronized
    fun accessToken(forceRefresh: Boolean = false): String {
        val refresh = store.get(REFRESH_TOKEN)
            ?: throw SpotifyException(SpotifyErrorCodes.NOT_CONNECTED, "Not connected to Spotify.")
        val expiresAt = store.get(EXPIRES_AT)?.toLongOrNull() ?: 0L
        val current = store.get(ACCESS_TOKEN)
        if (!forceRefresh && current != null && System.currentTimeMillis() < expiresAt - 60_000) return current

        val response = SpotifyHttp.request(
            "POST",
            TOKEN_URL,
            formBody = SpotifyHttp.form(
                mapOf("grant_type" to "refresh_token", "refresh_token" to refresh, "client_id" to CLIENT_ID),
            ),
        )
        if (response.status == 400 || response.status == 401) {
            // Revoked in Spotify's account settings, or expired: sign in again.
            signOut()
            throw SpotifyException(SpotifyErrorCodes.NOT_CONNECTED, "Spotify access was revoked. Connect again.")
        }
        if (response.status != 200) {
            throw SpotifyException(SpotifyErrorCodes.API_ERROR, "Couldn't refresh Spotify access.", response.status)
        }
        saveTokens(response)
        return store.get(ACCESS_TOKEN)!!
    }

    fun signOut() = store.clear()

    private fun saveTokens(response: SpotifyHttp.Response) {
        val json = response.json()
        val access = json.optString("access_token").ifBlank {
            throw SpotifyException(SpotifyErrorCodes.AUTH_FAILED, "Spotify returned no access token.")
        }
        store.put(ACCESS_TOKEN, access)
        store.put(EXPIRES_AT, (System.currentTimeMillis() + json.optLong("expires_in", 3600) * 1000).toString())
        // A refresh may omit refresh_token; keep the existing one then.
        json.optString("refresh_token").takeIf { it.isNotBlank() }?.let { store.put(REFRESH_TOKEN, it) }
    }

    companion object {
        val CLIENT_ID: String = BuildConfig.SPOTIFY_CLIENT_ID
        const val REDIRECT_URI = "sonora://spotify-callback"
        const val REDIRECT_SCHEME = "sonora"
        const val REDIRECT_HOST = "spotify-callback"
        const val SCOPES =
            "playlist-read-private playlist-read-collaborative playlist-modify-private playlist-modify-public"

        private const val AUTHORIZE_URL = "https://accounts.spotify.com/authorize"
        private const val TOKEN_URL = "https://accounts.spotify.com/api/token"
        private const val ACCESS_TOKEN = "spotify_access_token"
        private const val REFRESH_TOKEN = "spotify_refresh_token"
        private const val EXPIRES_AT = "spotify_expires_at"
        private const val PENDING_VERIFIER = "spotify_pending_verifier"
        private const val PENDING_STATE = "spotify_pending_state"

        /** Pure, so the URL can be unit-tested. */
        fun authorizeUrl(clientId: String, redirectUri: String, scopes: String, state: String, challenge: String): String =
            AUTHORIZE_URL + "?" + SpotifyHttp.form(
                linkedMapOf(
                    "client_id" to clientId,
                    "response_type" to "code",
                    "redirect_uri" to redirectUri,
                    "code_challenge_method" to "S256",
                    "code_challenge" to challenge,
                    "state" to state,
                    "scope" to scopes,
                ),
            )
    }
}
