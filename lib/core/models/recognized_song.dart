/// A song identified by the native recognition engine.
class RecognizedSong {
  const RecognizedSong({
    required this.provider,
    required this.providerId,
    required this.title,
    required this.artist,
    required this.recognizedAt,
    this.album,
    this.releaseDate,
    this.durationMs,
    this.isrc,
    this.spotifyTrackId,
    this.spotifyAlbumId,
    this.artworkUrl,
    this.confidence,
  });

  factory RecognizedSong.fromMap(Map<String, Object?> map) => RecognizedSong(
    provider: map['provider'] as String? ?? '',
    providerId: map['providerId'] as String? ?? '',
    title: map['title'] as String? ?? 'Unknown title',
    artist: map['artist'] as String? ?? 'Unknown artist',
    album: map['album'] as String?,
    releaseDate: map['releaseDate'] as String?,
    durationMs: (map['durationMs'] as num?)?.toInt(),
    isrc: map['isrc'] as String?,
    spotifyTrackId: map['spotifyTrackId'] as String?,
    spotifyAlbumId: map['spotifyAlbumId'] as String?,
    artworkUrl: map['artworkUrl'] as String?,
    confidence: (map['confidence'] as num?)?.toDouble(),
    recognizedAt: DateTime.fromMillisecondsSinceEpoch(
      (map['recognizedAt'] as num?)?.toInt() ?? 0,
    ),
  );

  final String provider;
  final String providerId;
  final String title;
  final String artist;
  final String? album;
  final String? releaseDate;
  final int? durationMs;
  final String? isrc;
  final String? spotifyTrackId;

  /// Lets "Open in Spotify" show the album with the track highlighted instead of autoplaying.
  final String? spotifyAlbumId;
  final String? artworkUrl;

  /// 0.0–1.0 where the provider reports it.
  final double? confidence;
  final DateTime recognizedAt;
}

/// Outcome of a successful `recognizeOnce` call (a match or a clean no-match).
class RecognitionAttempt {
  const RecognitionAttempt({
    required this.song,
    required this.elapsed,
    this.confident = true,
  });

  factory RecognitionAttempt.fromMap(Map<String, Object?> map) {
    final song = map['song'];
    return RecognitionAttempt(
      song: map['matched'] == true && song is Map
          ? RecognizedSong.fromMap(song.cast<String, Object?>())
          : null,
      elapsed: Duration(milliseconds: (map['elapsedMs'] as num?)?.toInt() ?? 0),
      confident: map['confident'] as bool? ?? true,
    );
  }

  final RecognizedSong? song;
  final Duration elapsed;

  /// False for a low-score (50–69) match: shown, but flagged as uncertain.
  final bool confident;

  bool get matched => song != null;
}

enum MicrophonePermission {
  granted,
  denied,
  permanentlyDenied;

  static MicrophonePermission parse(Object? value) => switch (value) {
    'granted' => granted,
    'permanently_denied' => permanentlyDenied,
    _ => denied,
  };
}
