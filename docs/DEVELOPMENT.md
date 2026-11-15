# Development setup (Windows)

## Toolchain used for v0.1.0

| Tool | Version |
|---|---|
| Flutter | 3.50.0 stable (Dart 3.14.0), at `C:\src\flutter` |
| Android Gradle Plugin | 9.3.1 (Flutter template) |
| Gradle | 9.5.0 (wrapper) |
| Kotlin | 2.4.20 |
| JDK | Android Studio JBR (OpenJDK 25); bytecode targets Java 17 |
| Android SDK | platform `android-37.0`, build-tools 36.0.0, NDK 28.2.13676358 |

Flutter is configured with:

```bash
flutter config --jdk-dir "C:\Program Files\Android\Android Studio\jbr" --android-sdk "%LOCALAPPDATA%\Android\Sdk"
```

## SDK levels

| Setting | Value | Why |
|---|---|---|
| `compileSdk` | 37 | Android 17 APIs |
| `targetSdk` | 36 | Raised to 37 after Android 17 behaviour changes are tested on device |
| `minSdk` | 24 | The lowest Flutter 3.50 supports. The original plan said 23, which Flutter no longer allows. |

## Outstanding environment items

- `flutter doctor` reports **cmdline-tools missing** and **licence status unknown**. Builds work anyway because the needed licences are already in the SDK `licenses/` folder. To clear the warnings, install *Android SDK Command-line Tools* from Android Studio (SDK Manager → SDK Tools), then run `flutter doctor --android-licenses`.

## Recognition provider (ACRCloud)

Without these steps the app still builds, but **Identify song** reports `PROVIDER_UNAVAILABLE`.

1. Create an ACRCloud project: Audio & Video Recognition, *Recorded Audio*, *Audio Fingerprinting*, the *ACRCloud Music* bucket, and the spotify and isrc external IDs.
2. Enter the project's host, access key and secret in the app under **Settings › Recognition**. For your own debug builds you can instead put them in `android/local.properties` (git-ignored):
   ```properties
   acrcloud.host=identify-<region>.acrcloud.com
   acrcloud.accessKey=...
   acrcloud.accessSecret=...
   ```
3. From [ACRCloudUniversalSDK](https://github.com/acrcloud/ACRCloudUniversalSDK) `libs/`, copy:
   - `acrcloud-universal-sdk-1.3.34.jar` into `android/app/libs/`
   - `arm64-v8a/libACRCloudUniversalEngine.so` into `android/app/src/main/jniLibs/arm64-v8a/`

   Both are git-ignored, because the SDK has no published licence.

Keys from `local.properties` are compiled into **debug builds only**; release builds never contain a key. Keys entered in Settings take priority and are stored encrypted on the phone. Still, don't share debug APKs built with your keys.

## Running on the Galaxy S24 Ultra

1. Settings → About phone → Software information → tap *Build number* 7 times.
2. Settings → Developer options → enable *USB debugging*.
3. Connect over USB and accept the RSA prompt on the phone.
4. Check that `flutter devices` lists the phone, then run `flutter run`.

## Checks before each commit

```bash
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

Kotlin JVM unit tests (policy, audio levels, song keys), run from `android/`:

```bash
gradlew :app:testDebugUnitTest
```

Instrumentation tests (database, encrypted storage, ACRCloud response parsing) run on a connected phone. Gradle's `connectedDebugAndroidTest` uninstalls the app afterwards, which wipes permissions and history, so install and run them directly:

```bash
gradlew :app:assembleDebugAndroidTest
adb install -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
adb shell am instrument -w dev.sonora.sonora.test/androidx.test.runner.AndroidJUnitRunner
adb uninstall dev.sonora.sonora.test
```
