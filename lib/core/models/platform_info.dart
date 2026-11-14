/// Device details reported by the native layer.
class PlatformInfo {
  const PlatformInfo({
    required this.manufacturer,
    required this.brand,
    required this.model,
    required this.device,
    required this.androidVersion,
    required this.sdkInt,
    required this.securityPatch,
    required this.isSamsung,
    required this.appVersion,
  });

  factory PlatformInfo.fromMap(Map<String, Object?> map) => PlatformInfo(
    manufacturer: map['manufacturer'] as String? ?? '',
    brand: map['brand'] as String? ?? '',
    model: map['model'] as String? ?? '',
    device: map['device'] as String? ?? '',
    androidVersion: map['androidVersion'] as String? ?? '',
    sdkInt: (map['sdkInt'] as num?)?.toInt() ?? 0,
    securityPatch: map['securityPatch'] as String?,
    isSamsung: map['isSamsung'] as bool? ?? false,
    appVersion: map['appVersion'] as String?,
  );

  final String manufacturer;
  final String brand;
  final String model;
  final String device;
  final String androidVersion;
  final int sdkInt;
  final String? securityPatch;
  final bool isSamsung;
  final String? appVersion;

  /// e.g. "samsung SM-S928B".
  String get displayName => '$manufacturer $model'.trim();
}
