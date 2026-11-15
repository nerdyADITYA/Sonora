# Privacy

Sonora listens to the world around you, so this page lists exactly what it does with that. It is checked against the code for each release (last review: v0.8.0).

## What never happens

- **No audio is stored or sent.** Captures live in memory only, for 3–12 seconds, and are overwritten with zeros right after use. Nothing is written to disk.
- **No account, analytics, ads or crash reporting.** Sonora has no server of its own.
- **No listening without you.** Ambient listening runs only after you turn it on. While it runs there is always a notification with a Stop button, and Android shows its microphone indicator.

## What leaves the phone, and to whom

| When | Sent to | What is sent |
|---|---|---|
| Identifying a song (manual or ambient) | ACRCloud, at the host of **your** project | An audio **fingerprint** computed on the phone (not the audio), plus your project's access key and a request signature |
| After a match, to show a cover | Spotify's public oEmbed endpoint (`open.spotify.com/oembed`) **or** Apple's iTunes Search API (`itunes.apple.com/search`) | The Spotify track ID, or the song's title and artist |
| Spotify connected: picking the usual release | Spotify Web API (`api.spotify.com`) | The song's title and artist (a search) |
| Spotify connected: adding to a playlist | Spotify Web API | The playlist and track IDs you chose |
| Spotify sign-in | Spotify Accounts (`accounts.spotify.com`) | The standard PKCE sign-in; no client secret exists |

**Open in Spotify** opens a Spotify search link in the Spotify app or your browser.

Ambient listening sends at most 200 recognition requests a day. It sends nothing while the room is quiet, while you're offline, or while the microphone is blocked.

## What stays on the phone

| Data | Where | Notes |
|---|---|---|
| Recognition history (songs, times, source, match score) | App-private SQLite database `sonora.db` | Delete single entries, songs or everything from History |
| Your ACRCloud keys | `sonora_provider_keys`, AES-256-GCM encrypted with an Android Keystore key | Entered in Settings › Recognition; never shown again or sent to the Flutter UI; **Remove keys** deletes them |
| Spotify tokens | `sonora_secure`, encrypted the same way | Deleted when you disconnect Spotify |
| Settings (default playlist, daily request count, whether listening was on) | App-private SharedPreferences | Nothing sensitive |

Android backup is disabled for both encrypted files, so they are never copied to a cloud backup. A restored copy couldn't be decrypted anyway, because the Keystore key never leaves the phone.

## Permissions

| Permission | Why |
|---|---|
| Microphone | Capturing the short samples that get fingerprinted |
| Notifications | The listening notification, with its Stop and Save actions |
| Internet, network state | Recognition, covers and Spotify; Sonora doesn't open the microphone without a working connection |
| Foreground service (microphone), wake lock | Keeping checks on schedule while the screen is off |

## Logs

Release builds log errors by type only, never song details, keys or tokens. Debug builds also log candidate songs, match scores and capture loudness, to tune matching.

## Reporting a problem

See [SECURITY.md](../SECURITY.md).
