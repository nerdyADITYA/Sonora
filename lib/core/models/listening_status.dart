/// Whether ambient listening is running, and whether this build can listen at all.
class ListeningStatus {
  const ListeningStatus({required this.listening, required this.available});

  factory ListeningStatus.fromMap(Map<String, Object?> map) => ListeningStatus(
    listening: map['listening'] as bool? ?? false,
    available: map['available'] as bool? ?? false,
  );

  final bool listening;

  /// False until the native audio service ships (Phase 3).
  final bool available;
}
