/// Plain-language explanations for native error codes, shared by the
/// manual Identify card and the ambient listening card.
String? recognitionErrorDetail(String? code) => switch (code) {
  null || 'CANCELLED' => null,
  'PERMISSION_DENIED' => 'Sonora needs the microphone to hear the music. Nothing is recorded or stored.',
  'PERMISSION_PERMANENTLY_DENIED' || 'PERMISSION_REQUIRED' =>
    'Enable it in Settings › Apps › Sonora › Permissions › Microphone.',
  'MICROPHONE_SILENT' => 'The microphone returned silence. Check that microphone access is on in Quick Settings.',
  'MICROPHONE_UNAVAILABLE' => 'The microphone is busy or unavailable. Close any app using it and try again.',
  'NETWORK_UNAVAILABLE' => "Couldn't reach ACRCloud. Sonora needs an internet connection to identify songs.",
  'INVALID_CREDENTIALS' =>
    'ACRCloud rejected the credentials. Check android/local.properties.',
  'NOT_CONFIGURED' =>
    'ACRCloud credentials are missing from android/local.properties.',
  'PROVIDER_UNAVAILABLE' => 'This build has no recognition engine. See docs/RECOGNITION_FEASIBILITY.md.',
  'QUOTA_EXCEEDED' => 'ACRCloud request limit reached. Try again later.',
  'BUSY' => 'A recognition is already running.',
  'LISTENING_ACTIVE' =>
    'Ambient listening is on, so songs are identified automatically.',
  'FOREGROUND_NOT_ALLOWED' => 'Android only allows listening to start while Sonora is open. Open the app and try again.',
  'SPOTIFY_NOT_CONFIGURED' => 'This build has no Spotify Client ID. Add spotify.clientId to android/local.properties.',
  'SPOTIFY_NOT_CONNECTED' => 'Connect your Spotify account in Settings first.',
  'SPOTIFY_AUTH_CANCELLED' => 'Spotify sign-in was cancelled.',
  'SPOTIFY_AUTH_FAILED' => "Spotify sign-in didn't complete. Try again.",
  'SPOTIFY_FORBIDDEN' => 'Spotify refused the request. Make sure your account is added under User Management in the Spotify dashboard.',
  'SPOTIFY_RATE_LIMITED' =>
    'Spotify is limiting requests. Try again in a minute.',
  'SPOTIFY_TRACK_NOT_FOUND' => "Couldn't find this song on Spotify.",
  'SPOTIFY_PLAYLIST_NOT_FOUND' =>
    'That playlist no longer exists on Spotify. Choose another playlist.',
  'SPOTIFY_API_ERROR' => 'Spotify returned an error. Try again later.',
  final other => 'Error code: $other',
};
