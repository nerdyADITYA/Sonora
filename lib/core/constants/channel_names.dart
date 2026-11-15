/// Channel and method names shared with the Kotlin bridge.
///
/// Keep in sync with `android/app/src/main/kotlin/dev/sonora/sonora/bridge/BridgeContract.kt`.
abstract final class ChannelNames {
  static const control = 'dev.sonora/control';
  static const events = 'dev.sonora/events';
}

abstract final class BridgeMethods {
  static const getPlatformInfo = 'getPlatformInfo';
  static const getListeningStatus = 'getListeningStatus';
  static const requestPermissions = 'requestPermissions';
  static const recognizeOnce = 'recognizeOnce';
  static const cancelRecognition = 'cancelRecognition';
  static const startListening = 'startListening';
  static const stopListening = 'stopListening';
  static const getRecognitionHistory = 'getRecognitionHistory';
  static const getSongDetail = 'getSongDetail';
  static const deleteRecognition = 'deleteRecognition';
  static const deleteSong = 'deleteSong';
  static const clearRecognitionHistory = 'clearRecognitionHistory';
  static const openInSpotify = 'openInSpotify';
  static const getSpotifyStatus = 'getSpotifyStatus';
  static const connectSpotify = 'connectSpotify';
  static const disconnectSpotify = 'disconnectSpotify';
  static const getSpotifyPlaylists = 'getSpotifyPlaylists';
  static const createSpotifyPlaylist = 'createSpotifyPlaylist';
  static const setDefaultSpotifyPlaylist = 'setDefaultSpotifyPlaylist';
  static const findSpotifyTrack = 'findSpotifyTrack';
  static const addToSpotifyPlaylist = 'addToSpotifyPlaylist';
  static const getSpotifySyncStatus = 'getSpotifySyncStatus';
  static const retrySpotifySync = 'retrySpotifySync';
  static const openBatterySettings = 'openBatterySettings';
  static const dismissListeningInterruption = 'dismissListeningInterruption';
  static const requestAddTile = 'requestAddTile';
  static const takeLaunchSongId = 'takeLaunchSongId';
  static const getRecognitionProvider = 'getRecognitionProvider';
  static const setAcrCloudKeys = 'setAcrCloudKeys';
  static const clearAcrCloudKeys = 'clearAcrCloudKeys';
  static const getPrivacyConsent = 'getPrivacyConsent';
  static const setPrivacyConsent = 'setPrivacyConsent';
}

abstract final class BridgeEventTypes {
  static const bridgeConnected = 'bridge_connected';
  static const recognitionCapturing = 'recognition_capturing';
  static const recognitionMatching = 'recognition_matching';
  static const listeningStatus = 'listening_status';
  static const songRecognized = 'song_recognized';
  static const historyChanged = 'history_changed';
  static const spotifyStatus = 'spotify_status';
  static const openSong = 'open_song';
}
