# Architecture

## Layers

| Layer | Owns |
|---|---|
| Flutter (`lib/`) | Screens, workflows, state (Riverpod) |
| `core/platform/sonora_platform.dart` | The only Dart code that touches platform channels |
| Kotlin `bridge/` | Translating channel calls to native components |
| Kotlin native components (later) | Audio capture, recognition, foreground service, notifications, Room DB |

Long-lived native work must never depend on `MainActivity` or a Flutter engine. Native components publish through `SonoraEvents.emit(...)`. If Flutter isn't listening, the event is dropped, so anything that must survive is written to the database instead.

## Bridge contract

Channels (defined in `BridgeContract.kt` and `channel_names.dart`; keep the two in sync):

- `MethodChannel` `dev.sonora/control`
- `EventChannel` `dev.sonora/events`

### Response envelope

Every method returns:

```json
{ "success": true, "data": { }, "error": null }
{ "success": false, "data": null, "error": { "code": "NOT_IMPLEMENTED", "message": "..." } }
```

Dart's `unwrapBridgeResponse` returns `data` or throws `PlatformFailure(code, message)`. UI copy is chosen from `code`; raw native exception text never crosses the bridge.

Error codes: `NOT_IMPLEMENTED`, `INVALID_ARGUMENT`, `INTERNAL_ERROR` (native), plus `BRIDGE_UNAVAILABLE` and `MALFORMED_RESPONSE` (Dart side).

### Methods

| Method | Status | `data` |
|---|---|---|
| `getPlatformInfo` | v0.1.0 | `manufacturer, brand, model, device, androidVersion, sdkInt, securityPatch, isSamsung, appVersion` |
| `getListeningStatus` | v0.3.0 | `listening, available, phase, nextCheckAt?, requestsToday, dailyBudget, lastSong?, lastSongId?, savedTo?, lastError?`; v0.7.0 adds `powerSave`, `interrupted` (Android stopped listening last time), `batteryUnrestricted` |
| `requestPermissions` | v0.3.0 | `microphone`, `notifications`: each `"granted" \| "denied" \| "permanently_denied"` (shows the system prompts if needed) |
| `startListening` | v0.3.0 | listening status. Starts the microphone foreground service; call only while the app is visible |
| `stopListening` | v0.3.0 | none; stops the service and releases the microphone |
| `recognizeOnce` | v0.2.0 | `matched: bool, song: RecognizedSong?, elapsedMs: int`. Captures about 10 s in the foreground, fingerprints it on the device, and matches it with ACRCloud |
| `cancelRecognition` | v0.2.0 | none; the pending `recognizeOnce` fails with `CANCELLED` |
| `getRecognitionHistory` | v0.4.0 | args `query?`, `sort` (`newest`/`oldest`/`title`/`artist`), `limit` (≤500), `offset`. Returns `entries: HistoryEntry[]`, `total` |
| `getSongDetail` | v0.4.0 | args `songId`. Returns `songId, song, firstHeardAt, timesHeard, recognitions: HistoryEntry[]`; `NOT_FOUND` if deleted |
| `deleteRecognition` | v0.4.0 | args `eventId`; the song is removed too when it has no recognitions left |
| `deleteSong` | v0.4.0 | args `songId`; removes the song and all its recognitions |
| `clearRecognitionHistory` | v0.4.0 | deletes all history |
| `openInSpotify` | v0.4.0 | args `title`, `artist`. Opens `open.spotify.com/search/<title artist>`, which shows the song in the Spotify app (or the browser) **without playing it**. Track and album links autoplay, and ACRCloud's album ID can be a compilation |
| `getSpotifyStatus` | v0.5.0 | `configured, connected, displayName?, defaultPlaylist?: {id, name}` |
| `connectSpotify` | v0.5.0 | none. Opens Spotify sign-in in the browser; the result arrives as a `spotify_status` event |
| `disconnectSpotify` | v0.5.0 | Spotify status. Deletes the stored tokens |
| `getSpotifyPlaylists` | v0.5.0 | `playlists: [{id, name, trackCount, imageUrl?}]` (owned or collaborative only), `hiddenCount` (followed playlists another account owns) |
| `createSpotifyPlaylist` | v0.5.0 | args `name`. Returns the new playlist (private) |
| `setDefaultSpotifyPlaylist` | v0.5.0 | args `id`, `name`. Returns Spotify status |
| `findSpotifyTrack` | v0.5.0 | args `songId`. `trackId, title, artist, album?, confirmed`; `confirmed: false` means a search result the user must approve |
| `addToSpotifyPlaylist` | v0.5.0 | args `songId, playlistId, playlistName?, trackId?`. `result: "added" \| "already_in_playlist"` |
| `getSpotifySyncStatus` | v0.5.0 | args `songId`. `items: PlaylistSyncItem[]` |
| `retrySpotifySync` | v0.5.0 | `retried` (failed adds pushed again), `updated` (songs switched to Spotify's usual release) |
| `dismissListeningInterruption` | v0.7.0 | none; clears `interrupted` |
| `openBatterySettings` | v0.7.0 | none; opens Sonora's app info page, where battery can be set to Unrestricted |
| `requestAddTile` | v0.7.0 | `result: "added" \| "already_added" \| "not_added" \| "unavailable" \| "unsupported"` (the system prompt needs Android 13+) |
| `takeLaunchSongId` | v0.7.0 | `songId?`: the song the notification was tapped for, returned once |
| `getRecognitionSettings`, `updateRecognitionSettings` | planned | currently return `NOT_IMPLEMENTED` |

`HistoryEntry`: `eventId, songId, source ("manual" | "ambient"), recognizedAt, song: RecognizedSong`.

`RecognizedSong`: `provider, providerId, title, artist, album?, releaseDate?, durationMs?, isrc?, spotifyTrackId?, artworkUrl?, confidence? (0–1), recognizedAt (epoch ms)`.

Recognition error codes: `PERMISSION_REQUIRED`, `MICROPHONE_UNAVAILABLE`, `MICROPHONE_SILENT` (privacy toggle on), `CANCELLED`, `BUSY`, `NOT_CONFIGURED`, `PROVIDER_UNAVAILABLE` (built without the SDK), `NETWORK_UNAVAILABLE`, `INVALID_CREDENTIALS`, `QUOTA_EXCEEDED`, `PROVIDER_ERROR`, `LISTENING_ACTIVE` (manual recognition while ambient listening is on), `FOREGROUND_NOT_ALLOWED` (service start refused by Android).

`recognizeOnce` also returns `confident`: false for a 50–69% match, which the app shows as "Possible match".

Spotify error codes: `SPOTIFY_NOT_CONFIGURED`, `SPOTIFY_NOT_CONNECTED`, `SPOTIFY_AUTH_CANCELLED`, `SPOTIFY_AUTH_FAILED`, `SPOTIFY_RATE_LIMITED`, `SPOTIFY_FORBIDDEN` (account not under User Management, or the owner lacks Premium), `SPOTIFY_TRACK_NOT_FOUND`, `SPOTIFY_PLAYLIST_NOT_FOUND` (the playlist was deleted; the default is forgotten and the add isn't retried), `SPOTIFY_NEEDS_MATCH`, `SPOTIFY_API_ERROR`; network failures use `NETWORK_UNAVAILABLE`.

Listening phases (`phase`): `stopped`, `waiting`, `listening`, `matching`, `paused_budget`, `microphone_blocked`, `offline` (no internet; microphone off).

Unknown methods return Flutter's standard `notImplemented`.

### Events

Envelope: `{ "type": String, "timestamp": epochMillis, "data": Map? }`

| Type | Status | Sent when |
|---|---|---|
| `bridge_connected` | v0.1.0 | Flutter subscribes to the events channel |
| `recognition_capturing` | v0.2.0 | the microphone starts capturing for `recognizeOnce` |
| `recognition_matching` | v0.2.0 | capture is done and the fingerprint is being matched |
| `listening_status` | v0.3.0 | the service's state changes. `data` is the same map as `getListeningStatus` |
| `history_changed` | v0.4.0 | history was added to, edited or deleted; lists reload |
| `spotify_status` | v0.5.0 | Spotify sign-in finished, failed (`error`), or the connection or default playlist changed. `data` is the same map as `getSpotifyStatus` |
| `open_song` | v0.7.0 | the notification was tapped while the app was running. `data`: `songId` |
| `song_recognized` | v0.3.0 | ambient listening found a new song (duplicates are suppressed). `data` is a `RecognizedSong` |

## Recognition (native)

```
RecognitionManager ── AudioCaptureManager (AudioRecord, 44.1 kHz PCM16 mono, memory only, wiped after use)
        │
        └── RecognitionEngine ← RecognitionEngineFactory
                ├── AcrCloudRecognitionEngine   (src/acrcloud/kotlin, compiled when the SDK JAR is present)
                └── stub engine                 (src/noAcrcloud/kotlin, returns PROVIDER_UNAVAILABLE)
```

### Choosing a match

ACRCloud can return several candidates. `MatchSelector` drops any below 50, takes the best, and among candidates with the same title within 10 points prefers the earliest release (so a compilation doesn't win). A best score of 70 or more is accepted. Between 50 and 69, ambient listening holds the match and records again straight away, saving it only if the second sample names the same title and primary artist within 3 minutes. If that sample comes back empty, it tries up to twice more before backing off, so one blank sample during a quiet passage doesn't lose the song. Real scores seen on a Galaxy S24 Ultra: correct matches 58–100, wrong ones 28 and 64.

Ambient listening also keeps 40–49 results as `RecognitionOutcome.Tentative`. They are never saved on their own score, but they can confirm or be confirmed by an agreeing sample (AP Dhillon's "Wo Noor" scored 43, then 55). Manual recognition treats them as no match.

Sonora owns the microphone. ACRCloud's SDK is used only to fingerprint PCM and send the fingerprint. By default `ACRCloudClient.initWithConfig` starts its own 8 kHz "pre-record" (`reservedRecordBufferMS` = 3000). That recorder held the microphone next to Sonora's captures and pushed ambient scores down to 46–67. `AcrCloudRecognitionEngine` therefore sets `recorderType = USER` and `reservedRecordBufferMS = 0`, so the SDK never opens an `AudioRecord`.

## History (Phase 4)

`HistoryRepository` (Kotlin) owns a plain SQLite database, `sonora.db`, through `SQLiteOpenHelper`. Room was considered but not used: it would add the KSP processor and three dependencies that must track AGP 9 and Kotlin versions, which isn't worth it for two tables. Migrations go in `SonoraDatabase.onUpgrade`.

| Table | Purpose |
|---|---|
| `songs` | One row per distinct song. `song_key` is unique: provider track ID, else ISRC, else normalised title and artist (`SongKeys`). Later matches fill in missing metadata but never blank out known fields |
| `recognition_events` | One row per recognition: `recognized_at`, `provider`, `confidence`, `recognition_mode` (`online`), `source` (`manual` / `ambient`). Deleting a song cascades here |

Ambient matches are saved with a 15-minute suppression window checked in the database, so a song still playing after an app restart isn't saved or announced twice. Manual matches are always saved. Artwork is looked up once per song and stored. `songs.spotify_album_id` was added in schema v2. Flutter reads history only through the bridge, and the native side emits `history_changed` after every write.

## Spotify (Phase 5)

Native code in `spotify/` owns everything; Flutter never sees a token.

- **Sign-in:** Authorization Code with PKCE and redirect `sonora://spotify-callback`, caught by `MainActivity` (singleTop). No client secret exists in the app. Tokens are AES-256-GCM encrypted with an Android Keystore key (`SecureTokenStorage`) and excluded from backup. Access tokens refresh automatically; a 401 retries once.
- **API:** the February 2026 endpoints (`/me/playlists`, `POST /me/playlists`, `/playlists/{id}/items`). The app is in Development Mode, so up to 5 users listed under User Management, and the owner needs Premium.
- **Playlists:** Spotify only allows adds to playlists the signed-in account owns or that are collaborative. Others are counted in `hiddenCount` and the picker explains why they're missing.
- **Which track:** many songs exist on Spotify more than once (EP, album, deluxe). When connected, `SpotifyManager.preferredVersion` searches Spotify by title and primary artist and `SpotifyVersionPicker` takes the most popular exact match (or Spotify's top result when popularity isn't returned). Its album, release date, cover and track ID replace ACRCloud's before the song is saved; covers, remixes and other artists are never chosen. Songs saved earlier, or while disconnected, are updated by `refreshVersions` on the next app resume. Without a stored track ID, adding searches Spotify and the user confirms the match.
- **Adds:** `playlist_sync_queue` (schema v3) has one row per song and playlist (`UNIQUE(song_id, provider, playlist_id)`) with `pending`/`completed`/`failed`, attempts and the last error. Before adding, Sonora checks the playlist so a song is never added twice. Failed adds are retried (up to 5 attempts) whenever the app resumes while connected.

## Ambient listening (Phase 3)

`SonoraRecognitionService` is a `microphone`-type foreground service, started only from the visible app (Android requires this) and `START_NOT_STICKY` (Android won't let a microphone service restart itself from the background).

Each cycle runs on the service's worker thread:

```
budget left? ── no ──> paused_budget, re-check in 30 min
   │ yes
online? ── no ──> offline, re-check in 60 s   (microphone off, no request)
   │ yes
probe 3 s ── digital silence ──> microphone_blocked, retry in 30 s
   │      └─ quieter than -50 dBFS ──> waiting, retry in 20 s   (no request)
capture to 12 s → fingerprint → ACRCloud (1 request counted)
   ├─ match    → announce unless same track within 15 min; wait out the rest of the song (45 s–4 min)
   ├─ no match → back off 30 s → 60 s → 120 s
   └─ error    → retry in 60 s; credentials or engine errors stop the service
```

`ListeningPolicy` holds the numbers and is unit-tested. `RequestBudget` caps requests at 200 per local day. The microphone is open only during probe and capture; a partial wake lock keeps checks on schedule with the screen off. That wake lock is the main battery cost. It hasn't been measured yet (deferred in Phase 7).

`RecognitionNotificationManager` shows a single, silent, ongoing notification with the status or the last song (title, artist, album art), a **Stop** action and, when known, **Open in Spotify**. The lock screen shows only "Sonora is listening".

## Samsung integration (Phase 7)

- **Quick Settings tile:** `ListeningTileService` (`TOGGLEABLE_TILE`) follows `ServiceStateManager` through a listener while the panel is open. Android only lets a microphone foreground service start while the app is visible, so turning listening on opens the invisible `StartListeningActivity`. On Android 14+ this goes through `startActivityAndCollapse(PendingIntent)`; on the lock screen it goes through `unlockAndRun`. Turning listening off stops the service directly. `requestAddTile` uses `StatusBarManager.requestAddTileService`.
- **Notification:** the service reposts the notification from a `ServiceStateManager` listener. Tapping it opens `MainActivity` with the song's ID: a cold start reads it with `takeLaunchSongId`, and a running app gets an `open_song` event. **Save to <playlist>** is a broadcast to `SaveToPlaylistReceiver` (not exported). It uses `goAsync` and the same `SpotifyManager.addSong` queue as the app, then shows "Saved to …" on the notification. It appears only when the song has a Spotify track ID and a default playlist is set.
- **Recovery:** `ListeningRecovery` records that listening should be on, and clears it on every intended stop. If the flag is still set when the service isn't running, Android stopped it, and the app shows "Listening was stopped". It offers battery settings unless `isIgnoringBatteryOptimizations` is already true. A microphone service can't restart itself from the background, so this is a notice, not an automatic restart.
- **Battery saver:** when `PowerManager.isPowerSaveMode` is true, the waits after a quiet probe, a no-match or being offline are doubled (`ListeningPolicy.idleDelay`). The wait after a match isn't changed, so the next song isn't missed. Android pauses battery saver while charging, so test it unplugged (or with `adb shell dumpsys battery unplug`).

`app/build.gradle.kts` picks the source set depending on whether `android/app/libs/acrcloud-universal-sdk-*.jar` exists, so clones without the proprietary SDK still build.
