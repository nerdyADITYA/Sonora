# Changelog

This project follows [Semantic Versioning](https://semver.org/). Versions before 1.0 are betas.

## [0.8.0] - beta

### Added
- **Bring your own ACRCloud key:** enter your project's host, access key and secret in Settings › Recognition. They are stored encrypted with an Android Keystore key and never shown again.
- Privacy document (docs/PRIVACY.md), contribution guide, code of conduct, security policy and release guide.
- On-device tests for ACRCloud responses (every failure code) and for encrypted storage.

### Changed
- Release builds never contain ACRCloud keys. `local.properties` keys go into debug builds only.
- Release signing reads a git-ignored `android/key.properties`.
- Capture-loudness logging is limited to debug builds.

### Removed
- The unused `.env.example`.

## [0.7.0]

### Added
- Quick Settings tile to turn listening on or off, including from the lock screen.
- Notification actions: Save to your default Spotify playlist, and tap to open the song.
- A notice when Android stopped listening, linking to battery settings.
- Battery saver doubles the waits between idle checks.

### Fixed
- Ambient matching: the ACRCloud SDK's own 8 kHz recorder no longer holds the microphone next to Sonora's.
- Faster ambient confirmation: 12 s samples, an immediate second check, and retries after an empty sample. 40–49% results can be confirmed too.
- A deleted default playlist gets a clear message and isn't retried.

## [0.5.0]

### Added
- Spotify: PKCE sign-in, playlist picker, adding songs without duplicates, failed adds retried, and Spotify's usual release preferred so covers match.
- Online-only recognition: the microphone stays off without internet.

## [0.4.0]

### Added
- Local history (SQLite) with search, sorting, deleting and song detail pages.

## [0.3.0]

### Added
- Ambient listening as a microphone foreground service, with a loudness gate, backoff and a daily request budget.

## [0.2.0]

### Added
- Manual recognition with ACRCloud: on-device fingerprinting, with cover art.

## [0.1.0]

### Added
- Project foundation: Flutter dashboard, a Kotlin bridge, and platform info.
