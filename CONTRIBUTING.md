# Contributing to Sonora

Thanks for helping. Sonora is a small Flutter + Kotlin app for Android, and contributions of every size are welcome: bug reports, device test results, docs and code.

## Getting set up

Follow [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md). A fresh clone builds and runs **without** the ACRCloud SDK, but recognition then reports that no engine is available. To test recognition you need:

- the ACRCloud SDK files placed locally (they are git-ignored and must never be committed);
- your own ACRCloud project keys, either entered in Settings › Recognition, or in `android/local.properties` for debug builds.

## How the code is organised

- `lib/`: Flutter UI and workflows, feature-first (`features/<area>/{screens,widgets,providers}`), Riverpod for state.
- `android/app/src/main/kotlin/dev/sonora/sonora/`: everything Android-specific: microphone, recognition, the foreground service, the database, Spotify and notifications.
- The two talk only through the bridge in `bridge/` and `lib/core/platform/`. When you add a method, update both `BridgeContract.kt` and `channel_names.dart`, and list it in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Making a change

1. Open an issue first for anything bigger than a small fix, so we can agree on the approach.
2. Branch from `main` and keep each pull request to one change.
3. Add or update tests:
   - pure Kotlin logic → `android/app/src/test`;
   - anything that needs Android (database, Keystore, `org.json`) → `android/app/src/androidTest`;
   - UI → `test/widget`, using `FakePlatform`.
4. Run the checks:
   ```bash
   flutter analyze
   flutter test
   cd android && ./gradlew testDebugUnitTest
   ```
   With a phone connected, also run the instrumented tests (see DEVELOPMENT.md).
5. Use [Conventional Commits](https://www.conventionalcommits.org/) for messages, e.g. `fix: release the microphone when capture fails`.

## Ground rules

- **Privacy first.** No audio may be written to disk or sent anywhere. Anything new that leaves the phone must be added to [docs/PRIVACY.md](docs/PRIVACY.md) in the same pull request.
- **No secrets in git.** No keys, tokens, keystores or `local.properties`, and no ACRCloud SDK binaries.
- **Tokens and keys stay native.** Flutter never receives a Spotify token or an ACRCloud secret.
- Match the existing style. `dart format` and the analyzer settle Dart formatting.

## Code of conduct

Everyone taking part is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
