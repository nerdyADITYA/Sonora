# Sonora

**Discover the music around you.**

Sonora is an open-source Android app for ambient music recognition. Once you turn listening on, it identifies songs playing around you, keeps a local history, and lets you save them to your streaming service. It's built to feel like a system feature, not an app you have to remember to open.

> **Status: v0.7.0, Samsung integration.** Sonora identifies songs on demand or in the background, keeps a searchable history on your phone, and adds songs to your Spotify playlists. Listening can be switched from Quick Settings, and songs saved straight from the notification.

## What works today

- **Identify song:** a 10 s capture, fingerprinted on the device and matched by ACRCloud, showing title, artist, album and cover art
- **Ambient listening:** a user-started foreground service with a persistent notification and a Stop button. It checks for music on a cost-aware schedule (loudness gate, waits out matched songs, backs off on misses, 200 checks a day at most)
- **History:** every recognition saved locally (SQLite), grouped by day, with search, sorting, swipe-to-delete, clear-all, and a detail page per song (cover, times heard, ISRC, Open in Spotify)
- **Spotify:** sign in with PKCE (no client secret), pick or create a playlist, and add songs from History. Each song is added to a playlist at most once, and failed adds are retried. When Spotify is connected, Sonora uses the release Spotify usually shows, so covers match the Spotify app
- **Match quality:** 70% and up is accepted. Manual recognition shows 50–69% as "Possible match" and rejects anything lower. Ambient listening saves a match under 70% only when a second check straight after names the same song, and it also holds 40–49% results for that check
- **Quick Settings tile:** turns listening on or off and shows its state (the last song, "No internet", "Microphone blocked", "Daily limit reached"). It works from the lock screen after unlocking. Settings has a button to add the tile
- **Notification actions:** **Save to <playlist>** adds the last song to your default Spotify playlist without opening the app, and tapping the notification opens that song
- **Stays on, or says why it didn't:** listening survives swiping the app away. If Android stops it anyway, the app says so next time and links to battery settings. With battery saver on, idle checks happen half as often
- **Online only:** recognition needs an internet connection. Without one, Sonora doesn't open the microphone; History still works offline. Offline recognition (Phase 6) is deferred
- Dark, One UI-inspired dashboard (Flutter + Riverpod)
- A Flutter ↔ Kotlin bridge over `dev.sonora/control` and `dev.sonora/events` with structured responses

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

Sonora is designed around these rules: no permanent audio recordings, in-memory buffers only, a visible indicator and stop control whenever it's listening, and clear disclosure of any recognition provider that receives audio-derived data. Recognition sends ACRCloud an audio **fingerprint**, never the recording. After a match, Sonora looks up album artwork by sending the Spotify track ID to Spotify's public oEmbed endpoint, or the title and artist to the iTunes Search API. No audio is involved. With Spotify connected, Sonora searches Spotify by title and artist to find the usual release, and adds songs only when you ask. Spotify tokens are encrypted with an Android Keystore key and never leave the native layer.

## License

[Apache License 2.0](LICENSE). Third-party recognition SDKs and music catalogs carry their own terms, and the Apache licence does not grant redistribution rights for them.
