import '../errors/platform_failure.dart';

/// Parses the `{ success, data, error }` envelope returned by every bridge method.
///
/// Returns the `data` map on success and throws [PlatformFailure] otherwise.
Map<String, Object?> unwrapBridgeResponse(Object? raw) {
  if (raw is! Map) {
    throw const PlatformFailure(
      PlatformFailure.malformedResponse,
      'Expected a response map from the native bridge.',
    );
  }
  final response = raw.cast<String, Object?>();

  if (response['success'] == true) {
    final data = response['data'];
    return data is Map ? data.cast<String, Object?>() : const {};
  }

  final error = response['error'];
  if (error is Map) {
    throw PlatformFailure(
      error['code'] as String? ?? PlatformFailure.malformedResponse,
      error['message'] as String? ?? 'Unknown native error.',
    );
  }
  throw const PlatformFailure(
    PlatformFailure.malformedResponse,
    'Native bridge reported failure without an error.',
  );
}
