/// Where ACRCloud keys come from. The key and secret themselves never reach Flutter.
enum KeySource { settings, build, none }

class RecognitionProvider {
  const RecognitionProvider({
    required this.sdkAvailable,
    required this.source,
    this.host,
  });

  factory RecognitionProvider.fromMap(Map<String, Object?> map) =>
      RecognitionProvider(
        sdkAvailable: map['sdkAvailable'] as bool? ?? false,
        source: switch (map['source']) {
          'settings' => KeySource.settings,
          'build' => KeySource.build,
          _ => KeySource.none,
        },
        host: map['host'] as String?,
      );

  /// False for builds made without the ACRCloud SDK.
  final bool sdkAvailable;
  final KeySource source;

  /// The ACRCloud project host in use, e.g. identify-eu-west-1.acrcloud.com.
  final String? host;

  bool get configured => source != KeySource.none;
}
