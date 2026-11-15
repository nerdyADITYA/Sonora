# Releasing

## Before a release

1. On `main`, run the checks: `flutter analyze`, `flutter test`, the Kotlin unit tests (`android/gradlew testDebugUnitTest`) and the on-device tests (see [DEVELOPMENT.md](DEVELOPMENT.md)).
2. Bump `version:` in `pubspec.yaml` (`x.y.z+build`) and add a section to [CHANGELOG.md](../CHANGELOG.md).
3. Check that nothing secret is staged: `git status` must not list `local.properties`, `key.properties`, keystores, `.env`, or ACRCloud SDK files (`*.jar`, `*.so`).

## Signing key (one time)

Release builds are signed with a key that stays on your machine and is never committed. Create it with the JDK's `keytool`. It usually isn't on the PATH, but Android Studio's bundled JBR includes it.

Windows (PowerShell):

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v -keystore "$HOME\sonora-release.jks" -alias sonora -keyalg RSA -keysize 4096 -validity 10000
```

macOS / Linux (adjust the path if Android Studio is installed elsewhere):

```bash
"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" -genkeypair -v -keystore ~/sonora-release.jks -alias sonora -keyalg RSA -keysize 4096 -validity 10000
```

Keep the `.jks` file and its passwords backed up somewhere safe. Updates to an installed APK must be signed with the same key, and a lost key can't be recovered.

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
flutter build apk --release --target-platform android-arm64
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk` (about 18 MB).

- **64-bit ARM only.** The ACRCloud engine exists only for `arm64-v8a`, so `build.gradle.kts` leaves the other ABIs out of release builds. 32-bit and x86 devices refuse to install the APK instead of failing at runtime. Debug builds keep every ABI, for emulators.
- **No keys.** Release builds never contain ACRCloud keys, even when `local.properties` has them; those go into debug builds only. Users enter their own keys in Settings › Recognition.
- **Version.** Bump `version:` in `pubspec.yaml` first. Android uses the number after `+` (the version code) to allow updates, so it must go up with every APK you share.

Check the result (the build-tools and JBR paths are the Android Studio defaults on Windows):

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
aapt2 dump badging build/app/outputs/flutter-apk/app-release.apk | grep -E "^package|native-code"
```

The signer must be your certificate, not `CN=Android Debug`, and `native-code` must be `'arm64-v8a'`.

An APK signed with your key can't be installed over a debug build, because the signatures differ. Uninstall the debug build first, which deletes that copy's history, keys and Spotify sign-in.

## Publishing

Sonora releases are **source-only**. The ACRCloud SDK has no published licence allowing redistribution, so APKs that contain it aren't attached to GitHub releases.

1. Tag the commit: `git tag -a v0.8.0 -m "Sonora v0.8.0 beta"`, then `git push origin v0.8.0`.
2. On GitHub, go to Releases › Draft a new release, pick the tag, paste that version's CHANGELOG section, and tick **Set as a pre-release** for betas.
