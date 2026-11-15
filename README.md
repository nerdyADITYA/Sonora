<p align="center">
  <img src="docs/icon.png" alt="Sonora app icon: five rounded sound-wave bars" width="120">
</p>

<h1 align="center">Sonora</h1>

<p align="center"><b>Discover the music around you.</b></p>

Sonora is an open-source Android app that tells you what song is playing. You can ask it once, the way you would with a music-ID app, or switch on **ambient listening** and let it quietly notice songs in the background, all day. Every song it finds lands on a colourful board of album covers on your phone, and you can send any of them to a Spotify playlist with one tap.

> **Status: v0.9.0 beta.** Works end to end on a Galaxy S24 Ultra: on-demand and background recognition, a searchable history, Spotify playlists, a Quick Settings tile, light and dark themes, and a first-run privacy disclosure. Recognition uses your own free ACRCloud project, set up with an in-app guide.

---

## Compatible phones

There are thousands of Android phone models, so no list can name them all. Instead, Sonora works on **any phone that meets these four requirements**:

| Requirement | Why | How to check |
|---|---|---|
| **Android 7.0 or newer** | The oldest version Flutter supports | Settings › About phone › Software information › Android version |
| **64-bit ARM processor running 64-bit Android** (`arm64-v8a`) | ACRCloud's recognition engine only exists for 64-bit ARM | Nearly every phone sold since 2017 qualifies. If yours doesn't, Android says "App not installed" or "not compatible" when you open the APK, so nothing breaks. |
| **A microphone** | To hear the music | Every phone has one |
| **An internet connection** | Songs are identified online | Wi-Fi or mobile data |

Google Play services are **not** needed, so phones without them (for example Huawei models on EMUI) are fine too.

### Popular phones

✅ **Tested** means checked on a real device. ☑️ **Expected to work** means the phone meets every requirement above but hasn't been tried yet. If you try one, please report how it went in an issue.

| Brand | Models | Status |
|---|---|---|
| **Samsung** | Galaxy S24 Ultra | ✅ Tested |
| Samsung | Galaxy S8 and newer (including Plus, Ultra and FE models), Note 8 and newer, every Galaxy Z Fold and Z Flip | ☑️ Expected to work |
| Samsung | Galaxy A and M series from 2019 on | ☑️ Expected to work, except a few entry-level models that run 32-bit Android |
| **Google** | Every Pixel since the original (2016), including the "a" models and Pixel Fold | ☑️ Expected to work |
| **OnePlus** | OnePlus 5 and newer, every Nord | ☑️ Expected to work |
| **Xiaomi / Redmi / POCO** | Xiaomi 8 and newer, Redmi Note 7 and newer, every POCO | ☑️ Expected to work, except a few entry-level Redmi A models that run 32-bit Android |
| **Nothing / CMF** | Every Nothing Phone and CMF Phone | ☑️ Expected to work |
| **Motorola** | Moto G (2018 on), Edge series, Razr (2019 on) | ☑️ Expected to work, except some entry-level Moto E models that run 32-bit Android |
| **Oppo / Realme / Vivo / iQOO** | Models from 2019 on (Find, Reno, Realme GT and number series, Vivo X and V series) | ☑️ Expected to work |
| **Sony** | Xperia 1, 5 and 10 series | ☑️ Expected to work |
| **Huawei / Honor** | Models on EMUI or MagicOS (Android-based) | ☑️ Expected to work. HarmonyOS NEXT can't install Android apps. |
| **Android tablets** | 64-bit ARM tablets on Android 7.0+ (Galaxy Tab S series, Pixel Tablet, and so on) | ☑️ Expected to work; the layout is designed for phones |

### Not compatible

| Device | Why |
|---|---|
| iPhone and iPad | Sonora is Android-only |
| Phones older than Android 7.0 | Below the minimum Android version |
| 32-bit Android phones, including many "Android Go" budget models | The recognition engine is 64-bit only |
| Intel/x86 Android devices and most emulators | The recognition engine is ARM-only |
| Wear OS watches, Android TV and Android Auto | Not supported |

### Features that depend on the Android version

Everything above works from Android 7.0, but a few extras need a newer version:

| Feature | Needs |
|---|---|
| Status text under the Quick Settings tile ("Off", the last song…) | Android 10+ |
| **Add tile** button in Settings (on older versions, add the tile by editing Quick Settings) | Android 13+ |
| Themed icon matching your wallpaper colours | Android 13+ |
| Notification permission prompt (older versions allow notifications automatically) | Android 13+ |

---

## Contents

0. [Compatible phones](#compatible-phones)

1. [What Sonora does](#1-what-sonora-does)
2. [Getting started](#2-getting-started)
3. [How Sonora works: the big picture](#3-how-sonora-works-the-big-picture)
4. [The core layer, explained](#4-the-core-layer-explained)
5. [The journey of one song](#5-the-journey-of-one-song)
6. [Project tour: every folder and file](#6-project-tour-every-folder-and-file)
7. [What is stored, and where](#7-what-is-stored-and-where)
8. [Privacy and security](#8-privacy-and-security)
9. [Developing Sonora](#9-developing-sonora)
10. [Glossary](#10-glossary)
11. [Contributing and licence](#11-contributing-and-licence)

---

## 1. What Sonora does

| Feature | In plain words |
|---|---|
| **Identify song** | Tap the big lime button. Sonora listens for about 10 seconds and shows the title, artist, album and cover. |
| **Ambient listening** | Flip one switch and Sonora checks for music by itself, even with the app closed. A notification is always shown while it's on, with a Stop button. |
| **Your sounds (History)** | Every song found is saved on your phone and shown as a Pinterest-style board of album covers, grouped by day. Search it, sort it, swipe a cover away to delete it. |
| **Song pages** | Tap any cover to see when you first heard it, how many times, its release date, length and ISRC (a song's barcode-like ID). |
| **Spotify** | Connect your account, pick a playlist (or let Sonora create "Sonora discoveries"), and add songs. A song is never added to the same playlist twice. |
| **Quick Settings tile** | A "Sonora" tile in your pull-down panel switches listening on and off and shows what it's doing. |
| **Notification shortcuts** | Save the song just found to your Spotify playlist without opening the app, or tap to open its page. |
| **Light and dark themes** | A playful "Y2K pop" look: lilac and lime, chunky outlines, sticker-style labels. Follow your phone's setting or pick one. |
| **Privacy first** | A clear disclosure on first launch. No audio is ever saved or uploaded, only a fingerprint. No ads, no analytics, no account. |
| **Careful with your quota** | Ambient listening skips quiet rooms, waits for a song to end before checking again, and never sends more than 200 requests a day. |

What Sonora does **not** do: it doesn't work offline (it needs internet to identify songs), it doesn't record conversations, and it doesn't run on iPhones (it's Android-only).

---

## 2. Getting started

### Install the APK

1. Download `app-release.apk` from the [latest release](https://github.com/nerdyADITYA/Sonora/releases/latest). It needs a 64-bit Android phone running Android 7.0 or newer; almost every phone from the last several years qualifies.
2. Check the download: its SHA-256 is shown next to the file on the release page.
3. Open the APK and allow your browser or file manager to install apps when Android asks.
4. Open Sonora. Read the privacy disclosure, agree, and allow the microphone and notifications.
5. Tap **Set up ACRCloud** on Home. The guide walks through creating your own free ACRCloud project and entering its keys. No keys ship with the app.

**Spotify:** connecting Spotify only works for accounts added to the project's Spotify app, because it is still in Spotify's Development Mode. To use your own Spotify account, ask to be added, or build from source with your own Spotify Client ID.

**Updating:** install a newer APK over the old one; your history and keys are kept. A build you made yourself is signed with a different key, so Android won't install the release APK over it without uninstalling first, which deletes that copy's data.

### Build from source

Follow [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md), including adding the ACRCloud SDK files locally, then enter your ACRCloud keys in the app as above. Optionally add your own Spotify Client ID to `android/local.properties`. There's more in [section 9](#9-developing-sonora).

### Why "bring your own key"?

Every song lookup is a request to ACRCloud, a paid music-recognition service. If one shared key were built into the app, anyone could copy it out of the APK and use up the quota for everyone. Instead, each person creates a free ACRCloud project and pastes its keys into Sonora once. They're stored encrypted on the phone and never shown again.

---

## 3. How Sonora works: the big picture

Sonora is built from **two halves that talk to each other**:

```
┌──────────────────────────────────────────┐
│  FLUTTER (Dart)  ·  "the face"            │   lib/
│  Screens, buttons, themes, the board of   │
│  covers. Decides what you see.            │
└───────────────┬──────────────────────────┘
                │  the bridge: two named channels
                │  dev.sonora/control  (Flutter asks, Kotlin answers)
                │  dev.sonora/events   (Kotlin announces news)
┌───────────────▼──────────────────────────┐
│  KOTLIN (native Android)  ·  "the engine" │   android/app/src/main/kotlin/
│  Microphone, recognition, the background  │
│  service, the database, Spotify, the      │
│  notification, the tile, encryption.      │
└───────────────┬──────────────────────────┘
                │
     ACRCloud · Spotify · iTunes (covers)
```

**Why split it this way?** Flutter is great for building good-looking screens quickly. But the parts that make Sonora work, like using the microphone in the background, a notification that survives the app being closed, or the Quick Settings tile, are things only native Android code can do reliably. So the rule is: **Flutter draws, Kotlin does**. Recognition never depends on a Flutter screen being open. Ambient listening keeps going when you swipe the app away, because it lives entirely in Kotlin.

**How the two halves talk.** Think of the bridge as two walkie-talkie channels:

- **`dev.sonora/control`** is for questions and commands from the app: "start listening", "give me the history", "save these keys". Every answer comes back in the same envelope, `{ success, data, error }`, so the app always knows whether something worked and, if not, gets a stable error code like `NETWORK_UNAVAILABLE` that it turns into a friendly sentence.
- **`dev.sonora/events`** is for news from the engine: "I'm listening now", "history changed", "Spotify connected", "open this song". The screens listen and update themselves.

Sensitive things never cross the bridge. Your ACRCloud secret and Spotify tokens stay in Kotlin; the Flutter side only ever learns things like "keys are set" or "connected as Alex".

---

## 4. The core layer, explained

The **core layer** is the native Kotlin engine under `android/app/src/main/kotlin/dev/sonora/sonora/`. It's where all the real work happens. Here are its parts, from the microphone outwards.

### 4.1 Hearing: the microphone (`audio/`)

Sonora records **mono, 44.1 kHz** sound into the phone's memory, never to a file. A manual "Identify song" capture is 10 seconds. As soon as a sample has been used, the memory holding it is overwritten with zeros. It also measures how loud a sample is, so it can skip a silent room without asking ACRCloud anything.

### 4.2 Recognising: from sound to song (`recognition/`)

1. **Fingerprinting.** The ACRCloud SDK turns the sample into an **audio fingerprint** on the phone. A fingerprint is a compact summary of the sound's pattern. It identifies a song, but the original audio can't be rebuilt from it.
2. **Asking ACRCloud.** The fingerprint goes to your ACRCloud project, signed with your keys. ACRCloud answers with candidate songs and a **score** from 0 to 100 for each.
3. **Deciding what to trust** (`MatchSelector`). Scores are messy in the real world. A correct song can score 58 and a wrong re-upload can score 64. So Sonora uses three bands:
   - **70 or more:** confident. Accepted.
   - **50 to 69:** possible. A manual identify shows it as "Possible match". Ambient listening waits for a second check to name the same song before saving it.
   - **40 to 49:** tentative. Never accepted alone, but ambient listening holds on to it in case the next check agrees.
   - **Below 40:** ignored.
4. **Choosing the right version.** Many songs exist on Spotify several times (single, album, deluxe edition). If Spotify is connected, Sonora picks the version Spotify usually shows, so the cover and playlist adds match what you see in the Spotify app.
5. **Finding a cover.** ACRCloud doesn't send artwork, so Sonora looks it up from Spotify's public preview service, or from Apple's iTunes search, using only the song's ID or title and artist.
6. **Saving it** to your history, and announcing "history changed" so every screen refreshes.

Sonora is **online only**. If there's no internet, it doesn't even open the microphone, so nothing is captured that can't be matched.

### 4.3 Listening in the background (`services/`)

Ambient listening is an Android **foreground service**: background work that Android allows only with a visible notification. Each round, or "cycle", goes like this:

```
check internet ─► check daily budget ─► 3 s loudness probe
      │                                   │ too quiet? wait 20–30 s
      ▼                                   ▼
   offline?                       12 s sample ─► fingerprint ─► ACRCloud
   wait 60 s                                                       │
                     ┌─────────────────────────────────────────────┘
                     ▼
     confident match ─► save, update notification, wait for the song to end
     possible match  ─► check again 1 s later (up to 2 retries) to confirm
     no match        ─► wait 30 s, then 60 s, then up to 2 min
```

Between checks the microphone is **closed**. The timing rules live in `ListeningPolicy`:

- After a match, Sonora waits roughly until the song ends, between 45 seconds and 4 minutes.
- The same song heard again within 15 minutes isn't saved twice.
- With battery saver on, the waits double.
- A **daily budget** of 200 requests stops ambient listening from running up your ACRCloud bill. It resets at midnight.

If Android or One UI stops the service to save battery, Sonora can't restart the microphone from the background; Android doesn't allow that. Instead it notices next time you open the app, tells you what happened, and links to the battery setting that prevents it.

The **Quick Settings tile** can't start the microphone directly, because Android only allows that while an app is on screen. So it briefly opens an invisible screen (`StartListeningActivity`) that starts the service and disappears.

### 4.4 Remembering: the history database (`database/`)

A small SQLite database on the phone, `sonora.db`, with three tables:

| Table | Holds |
|---|---|
| `songs` | One row per distinct song: title, artist, album, cover link, Spotify ID, ISRC and so on. |
| `recognition_events` | One row each time a song was heard: when, how (manual or ambient) and the score. |
| `playlist_sync_queue` | One row per song-and-playlist pair, so a song is never added to the same playlist twice, and failed adds can be retried. |

Songs are matched up across recognitions by their provider ID, then ISRC, then a cleaned-up title and artist (`SongKeys`). That's how "Times heard: 3" works.

### 4.5 Spotify (`spotify/`)

- **Sign-in** uses **PKCE**, the method designed for mobile apps. Spotify's own page opens in your browser, so Sonora never sees your password, and there's no "client secret" to leak. Spotify sends you back to the app through the link `sonora://spotify-callback`.
- **Tokens** (the keys Spotify gives back) are encrypted on the phone and refreshed automatically.
- **Adding a song** goes through the sync queue: look up the Spotify track, add it to your playlist once, and mark it done. If the playlist was deleted, Sonora says so instead of failing silently.

### 4.6 Keeping secrets (`security/`)

`SecureTokenStorage` encrypts small secrets, like your ACRCloud keys and Spotify tokens, with **AES-256-GCM**, using a key locked inside the phone's **Android Keystore** hardware. The encrypted files are excluded from cloud backups. Even if someone copied them off the phone, they couldn't be decrypted elsewhere.

### 4.7 Consent (`privacy/`)

`PrivacyConsent` remembers whether you agreed to the disclosure shown on first launch. Every way into the microphone checks it: the app, the Quick Settings tile and the background service. Until you agree, recognition and listening refuse to start, and Android's microphone permission prompt isn't even shown. If the disclosure ever changes significantly, its version number goes up and everyone is asked again.

### 4.8 The notification (`notifications/`)

While listening is on, there's one silent notification. It shows the status or the last song found, with **Stop**, **Save to [your playlist]** and tap-to-open. On the lock screen it only says "Sonora is listening", so song titles aren't shown to people around you.

---

## 5. The journey of one song

Here's what happens when ambient listening is on and a song starts playing in a café:

1. **Waiting.** The service is between checks, with the microphone off. The tile says what it's waiting for.
2. **Probe.** On schedule, it confirms the internet is up, opens the microphone for 3 seconds and measures the loudness. Loud enough? Continue.
3. **Sample.** It records 12 seconds into memory.
4. **Fingerprint and ask.** The ACRCloud SDK fingerprints it on the phone and sends only the fingerprint to your ACRCloud project.
5. **Judge.** ACRCloud says "Dua, score 58". That's a "possible" match, so the service checks again one second later. The second sample also says "Dua", so it's confirmed.
6. **Polish.** Sonora swaps in Spotify's usual release of the song and finds the cover.
7. **Save.** One new row in `recognition_events`, plus a row in `songs` if this is a new song. Then the event `history_changed` is announced.
8. **Tell you.** The notification shows "Dua", with **Save to Sonora discoveries**.
9. **Rest.** The service waits until the song is probably over before checking again.
10. **See it.** Next time you open Sonora, "Dua" is the big "last caught" card on Home and the newest cover on your board.

---

## 6. Project tour: every folder and file

```
Sonora/
├── lib/              the Flutter app (what you see)
├── android/          the native Android app (the engine) and build settings
├── test/             Flutter tests
├── docs/             design notes, privacy, development and release guides
├── pubspec.yaml      the Flutter project file: name, version, packages
└── README.md         this guide
```

### 6.1 Root files

| File | What it's for |
|---|---|
| `README.md` | This guide. |
| `CHANGELOG.md` | What changed in each version, newest first. |
| `CONTRIBUTING.md` | How to propose changes, and the checks to run first. |
| `CODE_OF_CONDUCT.md` | How people are expected to treat each other here (Contributor Covenant). |
| `SECURITY.md` | How to report a security problem privately. |
| `LICENSE` | The Apache 2.0 licence: what you may do with this code. |
| `pubspec.yaml` | The Flutter project file: app name, version (`0.9.0+9`), and the packages used: `flutter_riverpod` for state, `material_ui` for widgets, `shared_preferences` for small settings like the theme, `url_launcher` to open web pages. |
| `pubspec.lock` | The exact package versions in use, so every build is the same. |
| `analysis_options.yaml` | Code-style rules for `flutter analyze`. |
| `.gitignore` | Files Git must never upload: build output, `local.properties`, signing keys, the ACRCloud SDK files. |
| `.gitattributes` | Keeps line endings consistent between Windows and other systems. |
| `.metadata` | Flutter's own bookkeeping about how the project was created. |

### 6.2 `lib/`: the Flutter app

#### Entry point

| File | What it does |
|---|---|
| `main.dart` | Where the app starts. It sets up Riverpod (the state system) and launches `SonoraApp`. |

#### `lib/app/`: the app's frame

| File | What it does |
|---|---|
| `sonora_app.dart` | The root widget: app name, the light and dark themes, and which one is active. |
| `app_gate.dart` | The front door. On first launch it shows onboarding; once you've agreed or skipped, it shows the main app. |
| `home_shell.dart` | The bottom bar with **Home**, **History** and **Settings**. It keeps each tab's state when you switch, and opens a song's page when you tap the notification. |
| `theme/sonora_palette.dart` | Every colour, in a light and a dark set: lilac background, lime accent, pink, violet, yellow, teal and orange "pop" colours. It also gives each song a stable colour for its placeholder cover. |
| `theme/app_theme.dart` | Turns the palette into the full look: outlined pill buttons, lime switches, outlined dialogs and sheets, the nav bar, search bar and snackbars. |
| `theme/app_typography.dart` | The type style: the phone's own font at heavy weights with tight spacing, for the chunky Y2K headlines. |
| `theme/theme_mode_controller.dart` | Remembers whether you chose Phone, Light or Dark, and restores it at launch. |

#### `lib/core/`: shared plumbing

| File | What it does |
|---|---|
| `constants/channel_names.dart` | The names of the two bridge channels and every command and event. They must match Kotlin's `BridgeContract.kt`. |
| `platform/sonora_platform.dart` | **The only place Flutter talks to Kotlin.** Every screen goes through it, for things like "recognise once", "get history" and "set keys". It turns raw replies into proper Dart objects. |
| `errors/platform_failure.dart` | What a failed bridge call looks like: an error code plus a message. |
| `models/bridge_response.dart` | Unpacks the `{ success, data, error }` envelope. |
| `models/recognized_song.dart` | A recognised song: title, artist, album, cover, score and so on. Also the microphone permission states. |
| `models/history.dart` | History entries, pages of results, sort orders, and the full song details. |
| `models/listening_status.dart` | What ambient listening is doing: waiting, listening, matching, offline, paused, microphone blocked. |
| `models/spotify.dart` | Spotify connection status, playlists and the sync state of each add. No tokens. |
| `models/recognition_provider.dart` | Whether ACRCloud keys are set, and where from. Never the keys themselves. |
| `models/platform_info.dart` | Basic device details, such as the app version shown at the bottom of Settings. |
| `models/sonora_event.dart` | One piece of news from the engine, like `history_changed`. |

#### `lib/features/`: one folder per part of the app

Each feature has its own **screens** (whole pages), **widgets** (pieces of a page) and **providers** (the logic and state behind them).

**`dashboard/`: the Home tab**

| File | What it does |
|---|---|
| `screens/dashboard_screen.dart` | Home: the Sonora logo, the "what's that song?" headline, the light/dark button, then the cards below. Pull down to refresh. |
| `widgets/listening_card.dart` | The ambient listening switch. It turns lime while listening, explains any problem in plain words, and offers battery settings if Android stopped it. |
| `widgets/last_discovery_card.dart` | "last caught ✦": the newest song as a big cover card, with "new", time and confidence stickers. |
| `widgets/recent_pins.dart` | "recently caught": a small board of the songs found before that one. |
| `providers/dashboard_providers.dart` | Loads basic device information, such as the app version. |

**`recognition/`: identifying on demand**

| File | What it does |
|---|---|
| `widgets/recognize_card.dart` | The **Identify song** card. It shows progress, results and errors. If consent or keys are missing, it becomes a button that takes you to set them up. |
| `providers/recognition_controller.dart` | The steps of one manual identify: permission, listening, matching, then a result or an error. |
| `recognition_error_copy.dart` | Turns every engine error code into a friendly sentence ("Couldn't reach ACRCloud…"). |

**`listening/`**

| File | What it does |
|---|---|
| `providers/listening_controller.dart` | Mirrors the background service: starts and stops it, follows its live status, and notices if Android stopped it. |

**`history/`: the "your sounds" tab**

| File | What it does |
|---|---|
| `screens/history_screen.dart` | The board of every song, grouped by day, with search, sort, swipe-to-delete and "Clear history". |
| `screens/song_detail_screen.dart` | One song's page: big cover, Add to playlist, Open in Spotify, first heard, times heard, and every time it was heard. |
| `providers/history_providers.dart` | Loads history for the current search and sort, the latest songs for Home, and one song's details. Reloads whenever the engine says history changed. |

**`integrations/spotify/`**

| File | What it does |
|---|---|
| `add_to_spotify.dart` | The "Add to playlist" flow. Connected? Then which playlist? Then the right Spotify track (asks you to confirm if unsure). Then it's added exactly once. |
| `providers/spotify_controller.dart` | Spotify connection state, sign-in and sign-out, and the default playlist. |
| `widgets/spotify_card.dart` | The Spotify section in Settings. |
| `widgets/playlist_picker_sheet.dart` | The pop-up for choosing a playlist or creating "Sonora discoveries". |
| `widgets/spotify_logo.dart` | The Spotify logo, drawn as vector shapes. |

**`onboarding/`: first launch and consent**

| File | What it does |
|---|---|
| `screens/onboarding_screen.dart` | Three steps: the welcome ("hey, i'm sonora ✦"), "before we start" (the disclosure, with Agree or Not now), then "two quick permissions" (microphone and notifications). |
| `widgets/privacy_disclosure.dart` | The disclosure itself: microphone use, what leaves the phone, what stays, Spotify, and no ads. It also links to the full policy, and has a stand-alone page for agreeing later. |
| `providers/privacy_consent_controller.dart` | Reads, gives and withdraws consent, and holds the privacy policy link. |

**`settings/`: the Settings tab**

| File | What it does |
|---|---|
| `screens/settings_screen.dart` | The Settings page: appearance, recognition, music services, ambient listening, privacy, then the app version. |
| `screens/acrcloud_setup_screen.dart` | The four-step "set up recognition" guide: make an account, create a project, copy the keys, paste them in. It ends with "You're all set". |
| `widgets/appearance_card.dart` | Phone / Light / Dark. |
| `widgets/recognition_settings_card.dart` | Your ACRCloud project: enter, change or remove keys, and "How to get keys". |
| `widgets/listening_settings_card.dart` | Add the Quick Settings tile, and open One UI's battery setting. |
| `widgets/privacy_settings_card.dart` | The privacy policy link, and withdrawing (or giving) microphone consent. |
| `providers/recognition_provider_controller.dart` | Saves and removes ACRCloud keys through the engine. |

#### `lib/shared/`: building blocks used everywhere

| File | What it does |
|---|---|
| `widgets/pop.dart` | The Y2K pieces: `PopCard` (outlined card with a hard shadow), `PopChip` (sticker label), `WaveformLogo` (the five-bar logo), `PopHeader` (big lowercase page titles) and `SectionLabel`. |
| `widgets/pin_board.dart` | The Pinterest-style board. `Masonry` puts each cover in the shorter of two columns, and `PinCard` is one song pin. Cover shapes vary per song but never reshuffle. |
| `widgets/album_artwork.dart` | Album covers, with a coloured waveform placeholder while loading or when there's no cover. |
| `utils/formatting.dart` | Friendly dates and times: "Today", "Yesterday", "3:25". |

### 6.3 `android/`: the native app and its build

#### Build files

| File | What it does |
|---|---|
| `android/settings.gradle.kts`, `android/build.gradle.kts` | Tell Gradle (Android's build tool) what the project is made of. |
| `android/gradle.properties`, `android/gradle/wrapper/gradle-wrapper.properties` | Build settings, and which Gradle version to download. |
| `android/app/build.gradle.kts` | The main build recipe. App ID `dev.sonora.sonora`, minimum Android 7.0 (API 24), target API 36. It also handles four special cases: <ul><li>**ACRCloud keys** from `local.properties` go into debug builds only; release builds never contain a key.</li><li>The **Spotify Client ID** comes from `local.properties`.</li><li>**Signing:** release builds use your key from `key.properties`, or fall back to the debug key if there isn't one.</li><li>**64-bit ARM only:** release builds include only that ABI, because the ACRCloud engine exists only for it.</li></ul> |
| `android/app/proguard-rules.pro` | Tells the release optimiser not to strip the ACRCloud SDK classes, which its native engine needs. |

#### Source folders: `android/app/src/`

| Folder | What it's for |
|---|---|
| `main/` | The app itself: Kotlin code, the manifest and resources. |
| `acrcloud/` | The real recognition engine. It's used automatically when the ACRCloud SDK files are present. |
| `noAcrcloud/` | A stand-in used when the SDK isn't present (a fresh clone, for example). The app still builds and runs; Identify just says recognition isn't available. |
| `debug/`, `profile/` | Small manifest additions Flutter needs for development builds. |
| `test/` | Fast Kotlin tests that run on your computer. |
| `androidTest/` | Kotlin tests that run on a connected phone: the database, encryption and ACRCloud response handling. |

#### `main/AndroidManifest.xml`

The app's ID card for Android. It declares the permissions (microphone, notifications, internet, a microphone foreground service, and a wake lock so checks stay on schedule), the main screen, the background service, the Quick Settings tile, the notification's "Save" receiver, and the `sonora://spotify-callback` link for Spotify sign-in.

#### Kotlin code: `main/kotlin/dev/sonora/sonora/`

| File | What it does |
|---|---|
| `MainActivity.kt` | The one Android screen that hosts the Flutter app. It connects the bridge, shows Android's permission prompts, and catches the Spotify sign-in link. |

**`bridge/`: the walkie-talkies**

| File | What it does |
|---|---|
| `BridgeContract.kt` | The names of channels, commands and events, matching Flutter's `channel_names.dart`. |
| `SonoraMethodChannel.kt` | Answers every command from Flutter: identify, start or stop listening, history, Spotify, keys, consent and more. It checks inputs, runs slow work off the main thread, and always replies in the `{ success, data, error }` envelope. |
| `SonoraEventChannel.kt` | Sends engine news to Flutter. Other parts of the engine publish through it. |
| `LaunchRequests.kt` | Remembers "open this song" when the app was started from the notification, until Flutter is ready to show it. |

**`audio/`**

| File | What it does |
|---|---|
| `AudioCaptureManager.kt` | Opens the microphone, records into memory, measures loudness, and wipes the buffer afterwards. It reports clear errors: no permission, silent (the privacy toggle is on), or busy. |
| `AudioConfiguration.kt` | The recording format (44.1 kHz, mono, 16-bit) and the 10-second manual capture length. |

**`recognition/`**

| File | What it does |
|---|---|
| `RecognitionEngine.kt` | The shape every recognition provider must fit, so ACRCloud could one day be swapped for another service. |
| `RecognitionManager.kt` | Runs one manual identify from start to finish: online check, capture, match, pick the version, find the cover, save. |
| `RecognitionResult.kt` | The possible outcomes: match, tentative match, no match, or error. |
| `MatchSelector.kt` | The score rules from [section 4.2](#42-recognising-from-sound-to-song-recognition): which candidate to trust, and how much. |
| `AcrCloudCredentials.kt` | Your ACRCloud keys. It checks they look right, stores them encrypted, and tells the engine which to use: keys from Settings first, then debug-build keys. |
| `ArtworkResolver.kt` | Finds album covers through Spotify's public preview service, then iTunes search. |
| `Connectivity.kt` | "Is there working internet?" If not, the microphone isn't opened. |
| `SpotifyLinks.kt` | Builds "open in Spotify" links that show a song without starting playback. |
| `acrcloud/AcrCloudResponseParser.kt` | Reads ACRCloud's reply and turns each of its status codes into a clear outcome: no match, no internet, bad keys, quota used up. |
| `acrcloud/AcrCloudRecognitionEngine.kt` (in `src/acrcloud/`) | Drives the ACRCloud SDK: fingerprint on the phone, send, receive. It's rebuilt automatically when you change your keys. |
| `RecognitionEngineFactory.kt` (in `src/acrcloud/` and `src/noAcrcloud/`) | Picks the real engine or the stand-in, depending on whether the SDK is present. |

**`services/`: background listening**

| File | What it does |
|---|---|
| `SonoraRecognitionService.kt` | The ambient listening service: the cycle in [section 4.3](#43-listening-in-the-background-services), match confirmation, and saving songs. |
| `ListeningPolicy.kt` | All the timing rules: probe length, sample length, loudness threshold, waits, back-off, battery saver, duplicates and the daily budget. |
| `RequestBudget.kt` | Counts today's ACRCloud requests and resets at midnight. |
| `ServiceStateManager.kt` | What the listener is doing right now. It shares this with the app, the tile and the notification. |
| `ListeningRecovery.kt` | Notices if Android stopped listening without you asking, so the app can explain next time. |
| `ListeningTileService.kt` | The Quick Settings tile: shows the state and toggles listening. |
| `StartListeningActivity.kt` | The invisible screen the tile uses to start the microphone legally. It opens the app instead if consent or permission is missing. |

**`database/`**

| File | What it does |
|---|---|
| `SonoraDatabase.kt` | Creates and upgrades `sonora.db` and its three tables. |
| `HistoryRepository.kt` | The only way in or out of history: record a recognition, search, sort, delete, clear, and song details. Announces every change. |
| `HistoryModels.kt` | The shapes of history data, and "manual" versus "ambient". |
| `SongKeys.kt` | Decides when two recognitions are the same song. |
| `PlaylistSyncQueue.kt` | Remembers which songs went to which playlists, so nothing is added twice and failures can retry. |

**`spotify/`**

| File | What it does |
|---|---|
| `SpotifyAuth.kt` | Sign-in with PKCE through Spotify's own page, plus token refresh. |
| `Pkce.kt` | The small cryptographic helpers PKCE needs. |
| `SpotifyApi.kt` | The Spotify calls Sonora makes: your profile, your playlists, searching for a track, creating a playlist, checking whether a track is already in a playlist, and adding it. |
| `SpotifyHttp.kt` | The low-level web requests, and turning Spotify's errors into clear codes. |
| `SpotifyManager.kt` | Ties it together: connection status, the default playlist, adding songs through the queue, and retrying failed adds. |
| `SpotifyVersionPicker.kt` | Chooses Spotify's usual release of a song. |

**`notifications/`**

| File | What it does |
|---|---|
| `RecognitionNotificationManager.kt` | The listening notification: status, last song, Stop, Save and open. It shows less on the lock screen. |
| `SaveToPlaylistReceiver.kt` | Handles the notification's **Save** button without opening the app. |

**`security/`, `privacy/`**

| File | What it does |
|---|---|
| `security/SecureTokenStorage.kt` | Encrypted storage for keys and tokens (see [4.6](#46-keeping-secrets-security)). |
| `privacy/PrivacyConsent.kt` | Remembers your agreement to the disclosure (see [4.7](#47-consent-privacy)). |

#### Resources: `main/res/`

| Path | What it holds |
|---|---|
| `drawable/ic_launcher_foreground.xml` | The waveform app icon, drawn as vectors. |
| `drawable/ic_launcher_monochrome.xml` | A one-colour version of the icon, for Android 13's themed icons. |
| `mipmap-anydpi-v26/ic_launcher*.xml` | Combines the icon's background and foreground into an "adaptive icon" that fits any shape your phone uses. |
| `mipmap-*dpi/ic_launcher*.png` | Ready-made icon images for older Android versions, in five sizes. |
| `drawable/ic_stat_sonora.xml` | The small white waveform in the status bar. |
| `drawable/launch_background.xml`, `drawable-v21/…` | The colour shown for a split second while the app starts. |
| `values/sonora_colors.xml`, `values-night/…` | That start-up colour: lilac in light mode, deep purple in dark. |
| `values/ic_launcher_colors.xml` | The icon's background colour. |
| `values/styles.xml`, `values-night/styles.xml` | The window themes Android uses before Flutter draws. |
| `xml/backup_rules.xml`, `xml/data_extraction_rules.xml` | Keep the encrypted keys and tokens out of cloud backups and device transfers. |

#### Kotlin tests

| Test | Checks |
|---|---|
| `test/…/audio/AudioLevelTest.kt` | Loudness is measured correctly. |
| `test/…/database/SongKeysTest.kt` | The same song is recognised as the same song. |
| `test/…/privacy/PrivacyConsentTest.kt` | Consent to an older disclosure must be asked again. |
| `test/…/recognition/AcrCloudCredentialsTest.kt` | Bad hosts and keys are rejected with clear messages. |
| `test/…/recognition/MatchSelectorTest.kt` | The score bands pick the right candidate. |
| `test/…/recognition/SpotifyLinksTest.kt` | Spotify links are built correctly. |
| `test/…/services/ListeningPolicyTest.kt` | Waits, back-off and limits are right. |
| `test/…/services/ListeningStatusTextTest.kt` | The tile and notification show the right status text. |
| `test/…/spotify/PkceTest.kt` | PKCE codes follow the standard. |
| `test/…/spotify/SpotifyVersionPickerTest.kt` | The usual release of a song is chosen. |
| `androidTest/…/database/HistoryRepositoryTest.kt` | Saving, searching, sorting and deleting history on a real phone. |
| `androidTest/…/database/PlaylistSyncQueueTest.kt` | Songs are never queued twice for one playlist. |
| `androidTest/…/database/SonoraDatabaseMigrationTest.kt` | Upgrading the database keeps existing history. |
| `androidTest/…/recognition/AcrCloudResponseParserTest.kt` | Every ACRCloud reply and error code is handled. |
| `androidTest/…/security/SecureTokenStorageTest.kt` | Secrets are really encrypted, kept apart, and survive bad data. |

#### Files you create yourself (never uploaded)

| File | What it's for |
|---|---|
| `android/local.properties` | Your Android SDK path, and optionally your Spotify Client ID and debug-only ACRCloud keys. |
| `android/key.properties` + a `.jks` keystore | Your release signing key. See [docs/RELEASING.md](docs/RELEASING.md). |
| `android/app/libs/acrcloud-universal-sdk-*.jar`, `android/app/src/main/jniLibs/arm64-v8a/libACRCloudUniversalEngine.so` | The ACRCloud SDK, downloaded from ACRCloud's GitHub. See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md). |

### 6.4 `test/`: Flutter tests

These run on your computer with a **fake engine** (`FakePlatform`) in place of the real Kotlin side, so the screens can be tested quickly without a phone.

| File | Checks |
|---|---|
| `support/fake_platform.dart` | The fake engine: pretend history, listening, Spotify, keys and consent. |
| `support/pump.dart` | Starts the whole app on a phone-sized test screen. |
| `unit/sonora_platform_test.dart` | Bridge replies are read correctly, including failures and broken replies. |
| `widget/dashboard_screen_test.dart` | Home shows honest listening states, and identifying a song works. |
| `widget/history_screen_test.dart` | The board groups by day, searches, sorts, deletes, and opens song pages. |
| `widget/listening_recovery_test.dart` | "Listening was stopped" appears, with the battery link. |
| `widget/recognition_keys_test.dart` | Entering, saving and removing ACRCloud keys, and the guided setup from Home. |
| `widget/spotify_test.dart` | Connecting, choosing playlists, adding songs once, and confirming uncertain matches. |
| `widget/onboarding_test.dart` | The disclosure comes before permissions, skipping keeps the microphone off, and consent can be withdrawn. |
| `widget/appearance_test.dart` | Switching between light and dark. |

### 6.5 `docs/`: deeper reading

| File | What's in it |
|---|---|
| [`ARCHITECTURE.md`](docs/ARCHITECTURE.md) | The technical design: every bridge command and event, the database, the listening service and Spotify, in detail. |
| [`PRIVACY.md`](docs/PRIVACY.md) | Exactly what leaves the phone, to whom, and what stays. |
| [`DEVELOPMENT.md`](docs/DEVELOPMENT.md) | Setting up a computer to build Sonora: tools, the ACRCloud SDK, Spotify, running on a phone. |
| [`RELEASING.md`](docs/RELEASING.md) | Making a signed release APK and publishing it. |
| [`RECOGNITION_FEASIBILITY.md`](docs/RECOGNITION_FEASIBILITY.md) | Why ACRCloud was chosen, and the trade-offs. |
| [`SPOTIFY_FEASIBILITY.md`](docs/SPOTIFY_FEASIBILITY.md) | How the Spotify integration was designed, and its limits. |
| `icon.png` | The app icon used at the top of this guide. |

---

## 7. What is stored, and where

Everything Sonora keeps stays **on your phone**. Sonora has no server of its own.

| What | Where | How to remove it |
|---|---|---|
| Songs you've heard | `sonora.db` (private to the app) | Swipe a cover, delete a song, or "Clear history" |
| ACRCloud keys | Encrypted, `sonora_provider_keys` | Settings › Recognition › Remove keys |
| Spotify sign-in | Encrypted, `sonora_secure` | Settings › Spotify › Disconnect |
| Your consent | `sonora_consent` | Settings › Privacy › Withdraw microphone consent |
| Small settings (theme, default playlist, today's request count) | App-private settings files | Uninstalling Sonora removes everything |

Audio is **never** stored, not even temporarily on disk. The full breakdown is in [docs/PRIVACY.md](docs/PRIVACY.md).

---

## 8. Privacy and security

- **Only a fingerprint leaves the phone** for recognition, sent to *your* ACRCloud project. The recording stays in memory for a moment and is wiped.
- **To show a cover**, the song found (its Spotify ID, or title and artist) is looked up on Spotify or Apple iTunes. No audio is involved.
- **Spotify gets song details only when you've connected it**, to find tracks and add them to your playlists.
- **You can always tell when Sonora is listening.** A notification is always shown and Android's microphone indicator lights up. Stop is one tap away: in the notification, the tile or the app.
- **Consent comes first.** Nothing touches the microphone until you agree to the disclosure, and you can withdraw consent at any time.
- **Secrets are encrypted** with a hardware-backed Android Keystore key, never passed to the Flutter side, never logged, and never backed up.
- **No ads, analytics, crash reporting or accounts.**

Found a security problem? Please report it privately; see [SECURITY.md](SECURITY.md).

---

## 9. Developing Sonora

**You'll need:** Flutter (stable, 3.50 or newer), the Android SDK with platform 37, and Java 17 or newer (Android Studio's bundled one works). Step-by-step setup is in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

```bash
flutter pub get        # download packages
flutter analyze        # check code style and mistakes
flutter test           # run the Flutter tests
flutter run            # run on a phone connected over USB
```

Kotlin tests, from the `android/` folder:

```bash
./gradlew testDebugUnitTest            # fast tests on your computer
./gradlew connectedDebugAndroidTest    # tests on a connected phone
```

**Without the ACRCloud SDK** the app still builds and runs. Identify just reports that recognition isn't available. That's handy for working on screens.

**Building a release APK** (64-bit, signed with your key):

```bash
flutter build apk --release --target-platform android-arm64
```

See [docs/RELEASING.md](docs/RELEASING.md) for creating a signing key and checking the result.

**Before every commit:** run `flutter analyze` and `flutter test`, and check `git status` never lists `local.properties`, `key.properties`, keystores, `.env` or ACRCloud SDK files.

---

## 10. Glossary

| Term | Meaning |
|---|---|
| **Ambient listening** | Sonora checking for music by itself in the background, after you switch it on. |
| **Audio fingerprint** | A compact summary of a sound's pattern. It identifies a song, but the audio can't be rebuilt from it. |
| **ACRCloud** | The music-recognition service Sonora asks "what song is this?" |
| **Bridge** | The two channels Flutter (the screens) and Kotlin (the engine) use to talk. |
| **Flutter / Dart** | The toolkit, and its language, used for Sonora's screens. |
| **Kotlin** | The language of Sonora's native Android engine. |
| **Foreground service** | Android background work that's allowed to keep running because it shows a notification. |
| **Riverpod / provider** | How the Flutter side keeps track of state (like "is listening on?") and refreshes screens when it changes. |
| **Score / confidence** | How sure ACRCloud is about a match, from 0 to 100. |
| **ISRC** | International Standard Recording Code: a unique ID for a recording, like a barcode. |
| **PKCE** | A secure sign-in method for apps that needs no stored secret. Used for Spotify. |
| **Android Keystore** | A secure vault, often in hardware, for encryption keys that can't be copied off the phone. |
| **APK** | An Android app package: the file you install. |
| **ABI / arm64-v8a** | The type of processor an app is built for; `arm64-v8a` means 64-bit ARM, used by nearly all modern phones. |
| **Development Mode (Spotify)** | Spotify's default for new apps: only listed accounts can sign in. |

---

## 11. Contributing and licence

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md) first. Report security issues privately as described in [SECURITY.md](SECURITY.md). Every change is listed in [CHANGELOG.md](CHANGELOG.md).

Sonora is released under the [Apache License 2.0](LICENSE). Third-party recognition SDKs and music catalogs carry their own terms, and the Apache licence does not grant redistribution rights for them.
