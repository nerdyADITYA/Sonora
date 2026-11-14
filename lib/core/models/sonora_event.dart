/// An event pushed from the native layer over the events channel.
class SonoraEvent {
  const SonoraEvent({
    required this.type,
    required this.timestamp,
    this.data = const {},
  });

  factory SonoraEvent.fromNative(Object? raw) {
    final map = raw is Map
        ? raw.cast<String, Object?>()
        : const <String, Object?>{};
    final data = map['data'];
    return SonoraEvent(
      type: map['type'] as String? ?? 'unknown',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num?)?.toInt() ?? 0,
      ),
      data: data is Map ? data.cast<String, Object?>() : const {},
    );
  }

  final String type;
  final DateTime timestamp;
  final Map<String, Object?> data;
}
