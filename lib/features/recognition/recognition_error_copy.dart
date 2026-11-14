/// Plain-language explanations for native error codes, shared by the
/// manual Identify card and the ambient listening card.
String? recognitionErrorDetail(String? code) => switch (code) {
  null || 'CANCELLED' => null,
  'PERMISSION_DENIED' => 'Sonora needs the microphone to hear the music. Nothing is recorded or stored.',
  'PERMISSION_PERMANENTLY_DENIED' || 'PERMISSION_REQUIRED' =>
    'Enable it in Settings › Apps › Sonora › Permissions › Microphone.',
  'MICROPHONE_SILENT' => 'The microphone returned silence. Check that microphone access is on in Quick Settings.',
  'MICROPHONE_UNAVAILABLE' => 'The microphone is busy or unavailable. Close any app using it and try again.',
  'NETWORK_UNAVAILABLE' => "Couldn't reach ACRCloud. Check your connection.",
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
  final other => 'Error code: $other',
};
