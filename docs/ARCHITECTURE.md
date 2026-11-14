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
| `getListeningStatus` | v0.3.0 | `listening, available, phase, nextCheckAt?, requestsToday, dailyBudget, lastSong?, lastError?` |
| `requestPermissions` | v0.3.0 | `microphone`, `notifications`: each `"granted" \| "denied" \| "permanently_denied"` (shows the system prompts if needed) |
| `startListening` | v0.3.0 | listening status. Starts the microphone foreground service; call only while the app is visible |
| `stopListening` | v0.3.0 | none; stops the service and releases the microphone |
| `recognizeOnce` | v0.2.0 | `matched: bool, song: RecognizedSong?, elapsedMs: int`. Captures about 10 s in the foreground, fingerprints it on the device, and matches it with ACRCloud |
| `cancelRecognition` | v0.2.0 | none; the pending `recognizeOnce` fails with `CANCELLED` |
| `getRecognitionHistory`, `clearRecognitionHistory`, `getRecognitionSettings`, `updateRecognitionSettings` | planned | currently return `NOT_IMPLEMENTED` |

`RecognizedSong`: `provider, providerId, title, artist, album?, releaseDate?, durationMs?, isrc?, spotifyTrackId?, artworkUrl?, confidence? (0–1), recognizedAt (epoch ms)`.

Recognition error codes: `PERMISSION_REQUIRED`, `MICROPHONE_UNAVAILABLE`, `MICROPHONE_SILENT` (privacy toggle on), `CANCELLED`, `BUSY`, `NOT_CONFIGURED`, `PROVIDER_UNAVAILABLE` (built without the SDK), `NETWORK_UNAVAILABLE`, `INVALID_CREDENTIALS`, `QUOTA_EXCEEDED`, `PROVIDER_ERROR`, `LISTENING_ACTIVE` (manual recognition while ambient listening is on), `FOREGROUND_NOT_ALLOWED` (service start refused by Android).

Listening phases (`phase`): `stopped`, `waiting`, `listening`, `matching`, `paused_budget`, `microphone_blocked`.

Unknown methods return Flutter's standard `notImplemented`.

### Events

Envelope: `{ "type": String, "timestamp": epochMillis, "data": Map? }`

| Type | Status | Sent when |
|---|---|---|
| `bridge_connected` | v0.1.0 | Flutter subscribes to the events channel |
| `recognition_capturing` | v0.2.0 | the microphone starts capturing for `recognizeOnce` |
| `recognition_matching` | v0.2.0 | capture is done and the fingerprint is being matched |
| `listening_status` | v0.3.0 | the service's state changes. `data` is the same map as `getListeningStatus` |
| `song_recognized` | v0.3.0 | ambient listening found a new song (duplicates are suppressed). `data` is a `RecognizedSong` |

## Recognition (native)

```
RecognitionManager ── AudioCaptureManager (AudioRecord, 44.1 kHz PCM16 mono, memory only, wiped after use)
        │
        └── RecognitionEngine ← RecognitionEngineFactory
                ├── AcrCloudRecognitionEngine   (src/acrcloud/kotlin, compiled when the SDK JAR is present)
                └── stub engine                 (src/noAcrcloud/kotlin, returns PROVIDER_UNAVAILABLE)
```

## Ambient listening (Phase 3)

`SonoraRecognitionService` is a `microphone`-type foreground service, started only from the visible app (Android requires this) and `START_NOT_STICKY` (Android won't let a microphone service restart itself from the background).

Each cycle runs on the service's worker thread:

```
budget left? ── no ──> paused_budget, re-check in 30 min
   │ yes
probe 3 s ── digital silence ──> microphone_blocked, retry in 30 s
   │      └─ quieter than -50 dBFS ──> waiting, retry in 20 s   (no request)
capture to 10 s → fingerprint → ACRCloud (1 request counted)
   ├─ match    → announce unless same track within 15 min; wait out the rest of the song (45 s–4 min)
   ├─ no match → back off 30 s → 60 s → 120 s
   └─ error    → retry in 60 s; credentials or engine errors stop the service
```

`ListeningPolicy` holds the numbers and is unit-tested. `RequestBudget` caps requests at 200 per local day. The microphone is open only during probe and capture; a partial wake lock keeps checks on schedule with the screen off. That wake lock is the main battery cost, measured in Phase 7.

`RecognitionNotificationManager` shows a single, silent, ongoing notification with the status or the last song (title, artist, album art), a **Stop** action and, when known, **Open in Spotify**. The lock screen shows only "Sonora is listening".

`app/build.gradle.kts` picks the source set depending on whether `android/app/libs/acrcloud-universal-sdk-*.jar` exists, so clones without the proprietary SDK still build.
