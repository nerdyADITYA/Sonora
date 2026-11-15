# Security policy

## Supported versions

Only the latest release on `main` gets security fixes while Sonora is in beta.

## Reporting a vulnerability

Please **don't open a public issue** for security problems. Use GitHub's private reporting instead: the repository's **Security** tab, then **Report a vulnerability**. Expect a first reply within a week.

These are especially worth reporting:

- ways to read the stored ACRCloud keys or Spotify tokens, or to make the app leak them;
- the microphone staying on after listening is stopped, or recording without the notification;
- audio, or anything not listed in [docs/PRIVACY.md](docs/PRIVACY.md), leaving the phone;
- exported components (the activity, tile service or broadcast receiver) that another app can abuse.

## Design notes

- Secrets are stored AES-256-GCM encrypted with a key held in the Android Keystore, and are excluded from backups.
- Spotify sign-in uses PKCE, so there is no client secret anywhere.
- Release builds contain no ACRCloud key. Each user brings their own project keys, so one leaked key affects only its owner.
