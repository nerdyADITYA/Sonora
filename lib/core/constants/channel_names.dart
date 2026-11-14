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
}

abstract final class BridgeEventTypes {
  static const bridgeConnected = 'bridge_connected';
  static const recognitionCapturing = 'recognition_capturing';
  static const recognitionMatching = 'recognition_matching';
}
