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
