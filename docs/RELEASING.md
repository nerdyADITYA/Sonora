# Releasing

## Before a release

1. On `main`, run the checks: `flutter analyze`, `flutter test`, the Kotlin unit tests (`android/gradlew testDebugUnitTest`) and the on-device tests (see [DEVELOPMENT.md](DEVELOPMENT.md)).
2. Bump `version:` in `pubspec.yaml` (`x.y.z+build`) and add a section to [CHANGELOG.md](../CHANGELOG.md).
3. Check that nothing secret is staged: `git status` must not list `local.properties`, `key.properties`, keystores, `.env`, or ACRCloud SDK files (`*.jar`, `*.so`).

## Signing key (one time)

Release builds are signed with a key that stays on your machine and is never committed. Create it with the JDK's `keytool` (Android Studio's JBR includes it):

```bash
keytool -genkeypair -v -keystore ~/sonora-release.jks -alias sonora -keyalg RSA -keysize 4096 -validity 10000
```

`keytool` asks for the passwords; pick your own. Then create `android/key.properties` (git-ignored):

```properties
storeFile=C:/Users/<you>/sonora-release.jks
storePassword=...
keyAlias=sonora
keyPassword=...
```

Keep a backup of the keystore and its passwords. An installed app can only be updated by an APK signed with the same key.

Without `key.properties`, release builds fall back to the debug key, so contributors can still build them.

## Building

```bash
flutter build apk --release
```

Release builds never contain ACRCloud keys, even when `local.properties` has them; those go into debug builds only. Users enter their own keys in Settings › Recognition.

## Publishing

Sonora releases are **source-only**. The ACRCloud SDK has no published licence allowing redistribution, so APKs that contain it aren't attached to GitHub releases.

1. Tag the commit: `git tag -a v0.8.0 -m "Sonora v0.8.0 beta"`, then `git push origin v0.8.0`.
2. On GitHub, go to Releases › Draft a new release, pick the tag, paste that version's CHANGELOG section, and tick **Set as a pre-release** for betas.
