import 'recognized_song.dart';

/// What the native ambient listener is doing. Mirrors `ListeningPhase` in Kotlin.
enum ListeningPhase {
  stopped,
  waiting,
  listening,
  matching,
  pausedBudget,
  microphoneBlocked;

  static ListeningPhase parse(Object? value) => switch (value) {
    'waiting' => waiting,
    'listening' => listening,
    'matching' => matching,
    'paused_budget' => pausedBudget,
    'microphone_blocked' => microphoneBlocked,
    _ => stopped,
  };
}

/// Snapshot of ambient listening, from `getListeningStatus` or a `listening_status` event.
class ListeningStatus {
  const ListeningStatus({
    required this.listening,
    required this.available,
    this.phase = ListeningPhase.stopped,
    this.nextCheckAt,
    this.requestsToday = 0,
    this.dailyBudget = 0,
    this.lastSong,
    this.lastError,
  });

  factory ListeningStatus.fromMap(Map<String, Object?> map) {
    final next = (map['nextCheckAt'] as num?)?.toInt();
    final song = map['lastSong'];
    return ListeningStatus(
      listening: map['listening'] as bool? ?? false,
      available: map['available'] as bool? ?? false,
      phase: ListeningPhase.parse(map['phase']),
      nextCheckAt: next == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(next),
      requestsToday: (map['requestsToday'] as num?)?.toInt() ?? 0,
      dailyBudget: (map['dailyBudget'] as num?)?.toInt() ?? 0,
      lastSong: song is Map
          ? RecognizedSong.fromMap(song.cast<String, Object?>())
          : null,
      lastError: map['lastError'] as String?,
    );
  }

  static const stopped = ListeningStatus(listening: false, available: true);

  final bool listening;

  /// Whether this build supports ambient listening.
  final bool available;
  final ListeningPhase phase;
  final DateTime? nextCheckAt;
  final int requestsToday;
  final int dailyBudget;
  final RecognizedSong? lastSong;

  /// Error code from the last cycle or from a failed start, if any.
  final String? lastError;
}
