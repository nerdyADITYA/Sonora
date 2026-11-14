# Spotify feasibility (Phase 5, Gate D)

_Researched 2026-11-14. Re-check before acting; Spotify changed Web API access twice in 2026._

## Verdict

**Gate D: pass for personal use, with conditions.** Everything Phase 5 needs is still available to a new Development Mode app:

| Need | Endpoint | Available to new Dev Mode apps |
|---|---|---|
| Sign in without a client secret | Authorization Code + PKCE | ✅ |
| List my playlists | `GET /me/playlists` | ✅ |
| Create a "Sonora discoveries" playlist | `POST /me/playlists` (replaces `/users/{id}/playlists`) | ✅ |
| Add songs | `POST /playlists/{id}/items` (replaces `/tracks`), up to 100 per call | ✅ (one unanswered community report of a 405; verify in the prototype) |
| Skip songs already in the playlist | `GET /playlists/{id}/items` (own and collaborative playlists only) | ✅ |
| Find the track | Not needed in most cases: ACRCloud already returns the Spotify track ID. Search (`limit` ≤ 10) is the fallback | ✅ |

**Conditions**

1. **The app owner needs Spotify Premium.** Development Mode apps stop working if the owner's Premium lapses.
2. **At most 5 users per app,** each added under User Management. For an open-source release, each person registers their own Client ID ("bring your own Client ID"). Extended quota isn't realistic for an individual developer.
3. **Redirect URI rules (since April 2025):** HTTPS, or loopback `http://127.0.0.1` (never `localhost`; any port is allowed for loopback). Custom schemes such as `sonora://` aren't listed in the rules. If the dashboard accepts one, it is the simplest option on Android; otherwise sign-in uses a short-lived loopback listener inside the app.
4. **Quota is per developer account** (July 2026) and shared by all its Client IDs. 429 responses carry `reason: QUOTA_EXCEEDED`.

## Design

- **No client secret.** PKCE only; the Client ID lives in git-ignored `android/local.properties` (`spotify.clientId`).
- **Tokens** are stored in app-private storage, encrypted with an AES-GCM key held in the Android Keystore, and never sent to Flutter. Flutter only sees "connected as <display name>".
- **Scopes:** `playlist-read-private playlist-read-collaborative playlist-modify-private playlist-modify-public`.
- **Adding a song** uses the stored `spotify_track_id`. If it's missing, search `track:<title> artist:<artist>` and ask the user to confirm the match.
- **Duplicates:** check the playlist's items before adding; the `playlist_sync_queue` table records each add and retries failures without double-adding.
- **Manual first.** Phase 5 adds songs only when the user taps **Add to playlist**. Automatic saving is a later setting.

## Sources

- [February 2026 Dev Mode migration guide](https://developer.spotify.com/documentation/web-api/tutorials/february-2026-migration-guide)
- [July 2026 quota update](https://developer.spotify.com/blog/2026-07-23-web-api-quota-updates)
- [Add items to playlist](https://developer.spotify.com/documentation/web-api/reference/add-items-to-playlist)
- [Redirect URI rules](https://developer.spotify.com/documentation/web-api/concepts/redirect_uri)
- [PKCE flow](https://developer.spotify.com/documentation/web-api/tutorials/code-pkce-flow)
- [TechCrunch, Feb 2026](https://techcrunch.com/2026/02/06/spotify-changes-developer-mode-api-to-require-premium-accounts-limits-test-users/)
- [Community: 405 on /items](https://community.spotify.com/t5/Spotify-for-Developers/Spotify-Web-API-returns-405-when-adding-tracks-to-playlist-via/td-p/7540995)
