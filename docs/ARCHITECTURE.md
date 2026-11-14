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
| `requestPermissions`, `startListening`, `stopListening`, `getRecognitionHistory`, `clearRecognitionHistory`, `getRecognitionSettings`, `updateRecognitionSettings` | planned | currently return `NOT_IMPLEMENTED` |

Unknown methods return Flutter's standard `notImplemented`.

### Events

Envelope: `{ "type": String, "timestamp": epochMillis, "data": Map? }`

| Type | Status | Sent when |
|---|---|---|
| `bridge_connected` | v0.1.0 | Flutter subscribes to the events channel |
| `listening_started`, `listening_stopped`, `song_recognized`, `recognition_error` | planned | defined when Phase 2/3 ships |
