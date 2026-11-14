# Sonora

**Discover the music around you.**

Sonora is an open-source Android app for ambient music recognition. Once you turn listening on, it identifies songs playing around you, keeps a local history, and lets you save them to your streaming service. It's built to feel like a system feature, not an app you have to remember to open.

> **Status: v0.1.0, foundation.** The Flutter UI and the Kotlin bridge are in place. Sonora does **not** use the microphone or recognise music yet; that comes in Phase 2 (recognition prototype) and Phase 3 (background listening).

## What works today

- Dark, One UI-inspired dashboard (Flutter + Riverpod)
- A Flutter ↔ Kotlin bridge over `MethodChannel` (`dev.sonora/control`) and `EventChannel` (`dev.sonora/events`) with structured responses
- Device diagnostics reported from native code
- Listening status reported honestly as unavailable

## Architecture

Flutter handles the UI and app workflows. Kotlin owns everything Android-specific: the microphone, recognition, the foreground service, and notifications. Recognition will never depend on a Flutter widget being alive. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

```
lib/
  app/            app shell and theme
  core/           channel names, models, errors, platform bridge
  features/       feature-first modules (dashboard today)
android/app/src/main/kotlin/dev/sonora/sonora/
  MainActivity.kt
  bridge/         MethodChannel / EventChannel handlers and contract
```

## Development

Requirements: Flutter stable (3.50+), Android SDK with platform 37, and a JDK 17+ (Android Studio's bundled JBR works). Full setup is in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

```bash
flutter pub get
flutter analyze
flutter test
flutter run            # with a device connected over USB
```

## Privacy

Sonora is designed around these rules: no permanent audio recordings, in-memory buffers only, a visible indicator and stop control whenever it's listening, and clear disclosure of any recognition provider that receives audio-derived data. Recognition sends ACRCloud an audio **fingerprint**, never the recording. After a match, Sonora looks up album artwork by sending the Spotify track ID to Spotify's public oEmbed endpoint, or the title and artist to the iTunes Search API. No audio is involved.

## License

[Apache License 2.0](LICENSE). Third-party recognition SDKs and music catalogs carry their own terms, and the Apache licence does not grant redistribution rights for them.
