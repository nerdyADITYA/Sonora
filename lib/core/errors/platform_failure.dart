/// A structured failure from the native layer.
///
/// [code] is a stable identifier (for example `NOT_IMPLEMENTED`); UI copy is
/// chosen from it rather than from native exception text.
class PlatformFailure implements Exception {
  const PlatformFailure(this.code, this.message);

  /// The native side is missing (tests, unsupported platform).
  const PlatformFailure.unavailable()
    : code = bridgeUnavailable,
      message = 'Native bridge is not available.';

  static const bridgeUnavailable = 'BRIDGE_UNAVAILABLE';
  static const malformedResponse = 'MALFORMED_RESPONSE';
  static const notImplemented = 'NOT_IMPLEMENTED';

  final String code;
  final String message;

  @override
  String toString() => 'PlatformFailure($code): $message';
}
