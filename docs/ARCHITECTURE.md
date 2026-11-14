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
| `getListeningStatus` | v0.1.0 | `listening: bool, available: bool` (always `false/false` until Phase 3) |
| `requestPermissions` | v0.2.0 | `microphone: "granted" \| "denied" \| "permanently_denied"` (shows the system prompt if needed) |
| `recognizeOnce` | v0.2.0 | `matched: bool, song: RecognizedSong?, elapsedMs: int`. Captures about 10 s in the foreground, fingerprints it on the device, and matches it with ACRCloud |
| `cancelRecognition` | v0.2.0 | none; the pending `recognizeOnce` fails with `CANCELLED` |
| `startListening`, `stopListening`, `getRecognitionHistory`, `clearRecognitionHistory`, `getRecognitionSettings`, `updateRecognitionSettings` | planned | currently return `NOT_IMPLEMENTED` |

`RecognizedSong`: `provider, providerId, title, artist, album?, releaseDate?, durationMs?, isrc?, spotifyTrackId?, artworkUrl?, confidence? (0–1), recognizedAt (epoch ms)`.

Recognition error codes: `PERMISSION_REQUIRED`, `MICROPHONE_UNAVAILABLE`, `MICROPHONE_SILENT` (privacy toggle on), `CANCELLED`, `BUSY`, `NOT_CONFIGURED`, `PROVIDER_UNAVAILABLE` (built without the SDK), `NETWORK_UNAVAILABLE`, `INVALID_CREDENTIALS`, `QUOTA_EXCEEDED`, `PROVIDER_ERROR`.

Unknown methods return Flutter's standard `notImplemented`.

### Events

Envelope: `{ "type": String, "timestamp": epochMillis, "data": Map? }`

| Type | Status | Sent when |
|---|---|---|
| `bridge_connected` | v0.1.0 | Flutter subscribes to the events channel |
| `recognition_capturing` | v0.2.0 | the microphone starts capturing for `recognizeOnce` |
| `recognition_matching` | v0.2.0 | capture is done and the fingerprint is being matched |
| `listening_started`, `listening_stopped`, `song_recognized`, `recognition_error` | planned | defined when Phase 3 ships |

## Recognition (native)

```
RecognitionManager ── AudioCaptureManager (AudioRecord, 44.1 kHz PCM16 mono, memory only, wiped after use)
        │
        └── RecognitionEngine ← RecognitionEngineFactory
                ├── AcrCloudRecognitionEngine   (src/acrcloud/kotlin, compiled when the SDK JAR is present)
                └── stub engine                 (src/noAcrcloud/kotlin, returns PROVIDER_UNAVAILABLE)
```

`app/build.gradle.kts` picks the source set depending on whether `android/app/libs/acrcloud-universal-sdk-*.jar` exists, so clones without the proprietary SDK still build.
