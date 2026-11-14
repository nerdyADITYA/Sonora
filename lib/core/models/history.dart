import 'recognized_song.dart';

enum RecognitionSource {
  manual,
  ambient;

  static RecognitionSource parse(Object? value) =>
      value == 'ambient' ? ambient : manual;
}

enum HistorySort {
  newest('newest', 'Newest first'),
  oldest('oldest', 'Oldest first'),
  title('title', 'Title'),
  artist('artist', 'Artist');

  const HistorySort(this.wire, this.label);

  final String wire;
  final String label;

  /// Chronological sorts are grouped by day in the list.
  bool get isChronological => this == newest || this == oldest;
}

/// One recognition of a song, as listed in history.
class HistoryEntry {
  const HistoryEntry({
    required this.eventId,
    required this.songId,
    required this.source,
    required this.song,
  });

  factory HistoryEntry.fromMap(Map<String, Object?> map) => HistoryEntry(
    eventId: (map['eventId'] as num).toInt(),
    songId: (map['songId'] as num).toInt(),
    source: RecognitionSource.parse(map['source']),
    song: RecognizedSong.fromMap(
      (map['song'] as Map? ?? const {}).cast<String, Object?>(),
    ),
  );

  final int eventId;
  final int songId;
  final RecognitionSource source;

  /// The song, with `recognizedAt` set to this recognition's time.
  final RecognizedSong song;

  DateTime get recognizedAt => song.recognizedAt;
}

class HistoryPage {
  const HistoryPage({required this.entries, required this.total});

  factory HistoryPage.fromMap(Map<String, Object?> map) => HistoryPage(
    entries: [
      for (final e in map['entries'] as List? ?? const [])
        HistoryEntry.fromMap((e as Map).cast<String, Object?>()),
    ],
    total: (map['total'] as num?)?.toInt() ?? 0,
  );

  static const empty = HistoryPage(entries: [], total: 0);

  final List<HistoryEntry> entries;

  /// All recognitions in history, ignoring any search.
  final int total;
}

/// A song with every time it was recognised, newest first.
class SongDetail {
  const SongDetail({
    required this.songId,
    required this.song,
    required this.firstHeardAt,
    required this.recognitions,
  });

  factory SongDetail.fromMap(Map<String, Object?> map) => SongDetail(
    songId: (map['songId'] as num).toInt(),
    song: RecognizedSong.fromMap(
      (map['song'] as Map? ?? const {}).cast<String, Object?>(),
    ),
    firstHeardAt: DateTime.fromMillisecondsSinceEpoch(
      (map['firstHeardAt'] as num?)?.toInt() ?? 0,
    ),
    recognitions: [
      for (final e in map['recognitions'] as List? ?? const [])
        HistoryEntry.fromMap((e as Map).cast<String, Object?>()),
    ],
  );

  final int songId;
  final RecognizedSong song;
  final DateTime firstHeardAt;
  final List<HistoryEntry> recognitions;

  int get timesHeard => recognitions.length;
}
