# Recognition feasibility (Phase 2, Gate A)

_Researched 2026-11-14. Re-check vendor pages before acting; terms and prices change._

## Decision

**Provider: ACRCloud** (chosen 2026-11-14). ShazamKit was ruled out because it needs an Apple developer account with a Media Services key, which the project doesn't have. Its findings are kept below for reference.

**Gate A: technical pass for ACRCloud, with three conditions:**

1. **An ACRCloud account and project.** The maintainer creates these; they supply `host`, `accessKey` and `accessSecret`.
2. **Cost is controlled by design.** Billing is per recognition after a 14-day free trial (no card needed for the trial). Ambient listening must sample sparingly: recognise only when sound is music-like, back off after a match, and enforce a daily request budget.
3. **The SDK binaries stay out of the repo.** ACRCloud publishes no licence for its SDK. The JAR and `.so` files are downloaded by each developer and git-ignored.

## ACRCloud: findings

Source: [ACRCloudUniversalSDK](https://github.com/acrcloud/ACRCloudUniversalSDK) (linked from the [Android SDK docs](https://docs.acrcloud.com/sdk-reference/mobile-sdk/android))

| Question | Finding | Fit |
|---|---|---|
| Distribution | `acrcloud-universal-sdk-<ver>.jar` and `libACRCloudUniversalEngine.so` in the repo's `libs/` folder. No Maven or AAR | ⚠️ manual copy |
| Version / maintenance | Changelog runs to **1.3.34** (adds `MediaProjection` capture). **1.3.30** was rebuilt with NDK 29 and **16 KB alignment** | ✅ |
| Feeding our own audio | Low-level `recognize(buffer, bufferLen, sampleRate, nChannels)` takes 16-bit PCM. A built-in recorder also exists, with a 3 s pre-record buffer by default | ✅ Sonora keeps ownership of `AudioRecord` |
| Fingerprinting on the device | `createClientFingerprint(...)` followed by `recognizeFingerprint(...)` sends **a fingerprint, not raw audio** | ✅ meets the privacy rules |
| Continuous mode | No streaming session. Each recognition is a discrete request | ⚠️ Sonora schedules requests itself; cost scales with frequency |
| Offline | A separate `offline_version` matches against a local bucket the project builds itself | ✅ candidate for Phase 6 |
| Catalogue | Claims 150M+ tracks ([acrcloud.com](https://www.acrcloud.com)) | ✅ |
| Credentials | `host`, `accessKey`, `accessSecret` per project, embedded in the client | ⚠️ see below |
| Pricing | 14-day free trial; per-recognition pricing visible only after logging in to the console ([docs](https://docs.acrcloud.com/tutorials/recognize-music), [contact](https://www.acrcloud.com/contact)) | ⚠️ must be measured |
| Licence | No LICENSE file. A third-party mirror describes it as a commercial licence | ❌ don't redistribute binaries |

### Credentials

- The mobile SDK expects the access secret on the device, so anyone who unpacks a built APK can extract it.
- **Personal beta:** credentials come from git-ignored `android/local.properties` and are injected at build time. Builds stay on the maintainer's phone.
- **Public release (v1.0):** either "bring your own ACRCloud project" (credentials entered in Settings, stored in Android Keystore-backed storage) or a small signing proxy. Decide before Phase 8.

### Cost model to validate in the prototype

At one request every 30 s while listening, an 8-hour day costs about **960 requests**, which is too many. The Phase 3 design should cut that down:

- gate requests on a cheap on-device "is this music?" check (energy and spectral flatness)
- skip requests while the same track is likely still playing (suppression after a match)
- set a configurable daily cap, shown in Settings

## Repository rules

- `android/app/libs/*.jar`, `android/app/libs/*.aar` and `android/app/src/main/jniLibs/**/*.so` are git-ignored.
- ACRCloud credentials live only in `android/local.properties` (already git-ignored).
- The README states that recognition sends audio **fingerprints** to ACRCloud.

## Manual recognition prototype (built 2026-11-14)

Steps 1–3 are done. Step 4, the measurements, is pending.

1. The maintainer signs up at the ACRCloud console, creates an **Audio & Video Recognition** project with the **ACRCloud Music** bucket, and adds these lines to `android/local.properties`:
   ```properties
   acrcloud.host=identify-xx-xx.acrcloud.com
   acrcloud.accessKey=...
   acrcloud.accessSecret=...
   ```
2. The maintainer downloads the SDK from the ACRCloudUniversalSDK repo:
   - the JAR goes in `android/app/libs/`
   - `arm64-v8a/libACRCloudUniversalEngine.so` goes in `android/app/src/main/jniLibs/arm64-v8a/`
3. Build:
   - `RecognitionEngine` interface and `AcrCloudRecognitionEngine` (client fingerprint, then `recognizeFingerprint`)
   - `AudioCaptureManager` (PCM16 mono, foreground only, user-initiated, about 10 s capture, no service yet)
   - a `recognizeOnce` bridge method and a "Recognise" button showing title, artist and album
4. Measure success rate and latency on the S24 Ultra, quiet and noisy, and record the results here.

### Measurements (S24 Ultra)

| Scenario | Attempts | Matches | Median latency | Notes |
|---|---|---|---|---|
| Phone speaker, quiet room | | | | |
| Bluetooth speaker, 2 m | | | | |
| Noisy environment | | | | |

---

## Appendix: ShazamKit (not chosen)

- **Technically a strong fit.** Android SDK 2.1.1, minSdk 21, 16 KB page support since 2.1.0, PCM16 mono at 16, 32, 44.1 or 48 kHz, a streaming session for continuous audio, signatures sent instead of raw audio ([docs](https://developer.apple.com/shazamkit/android/)).
- **Blocker: a developer token is required.** It's a JWT signed with an Apple Media Services key from an Apple developer account ([DeveloperTokenProvider](https://developer.apple.com/shazamkit/android/shazamkit/com.shazam.shazamkit/-developer-token-provider/index.html)).
- **No published Android licence.** Questions about it on Apple's forums are unanswered ([779071](https://developer.apple.com/forums/thread/779071), [691860](https://developer.apple.com/forums/thread/691860)).
- **Worth revisiting** if an Apple developer account becomes available. It drops in behind the same `RecognitionEngine` interface.

## Rejected

- **AudD:** uploads raw audio clips, which conflicts with the privacy rules.
- **Unofficial Shazam APIs:** reverse-engineered, and they violate Shazam's terms.
