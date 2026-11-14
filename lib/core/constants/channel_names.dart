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
}

abstract final class BridgeEventTypes {
  static const bridgeConnected = 'bridge_connected';
  static const recognitionCapturing = 'recognition_capturing';
  static const recognitionMatching = 'recognition_matching';
  static const listeningStatus = 'listening_status';
  static const songRecognized = 'song_recognized';
  static const historyChanged = 'history_changed';
}
