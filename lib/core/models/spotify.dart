/// Connection state of the Spotify integration (no tokens ever reach Dart).
class SpotifyStatus {
  const SpotifyStatus({
    required this.configured,
    required this.connected,
    this.displayName,
    this.defaultPlaylist,
    this.error,
  });

  factory SpotifyStatus.fromMap(Map<String, Object?> map) {
    final playlist = map['defaultPlaylist'];
    return SpotifyStatus(
      configured: map['configured'] as bool? ?? false,
      connected: map['connected'] as bool? ?? false,
      displayName: map['displayName'] as String?,
      defaultPlaylist: playlist is Map
          ? SpotifyPlaylistRef.fromMap(playlist.cast<String, Object?>())
          : null,
      error: map['error'] as String?,
    );
  }

  static const disconnected = SpotifyStatus(configured: true, connected: false);

  /// False when the build has no Spotify Client ID.
  final bool configured;
  final bool connected;
  final String? displayName;
  final SpotifyPlaylistRef? defaultPlaylist;

  /// Error code from the last sign-in attempt, if it failed.
  final String? error;
}

class SpotifyPlaylistRef {
  const SpotifyPlaylistRef({required this.id, required this.name});

  factory SpotifyPlaylistRef.fromMap(Map<String, Object?> map) =>
      SpotifyPlaylistRef(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? 'Playlist',
      );

  final String id;
  final String name;
}

class SpotifyPlaylist extends SpotifyPlaylistRef {
  const SpotifyPlaylist({
    required super.id,
    required super.name,
    required this.trackCount,
    this.imageUrl,
  });

  factory SpotifyPlaylist.fromMap(Map<String, Object?> map) => SpotifyPlaylist(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? 'Playlist',
    trackCount: (map['trackCount'] as num?)?.toInt() ?? 0,
    imageUrl: map['imageUrl'] as String?,
  );

  final int trackCount;
  final String? imageUrl;
}

/// Playlists the user can add to, plus how many others are hidden because
/// another account owns them.
class SpotifyPlaylistPage {
  const SpotifyPlaylistPage({required this.playlists, this.hiddenCount = 0});

  final List<SpotifyPlaylist> playlists;
  final int hiddenCount;
}

/// The Spotify track for a history song. [confirmed] is false for a search
/// match, which the user must approve before it's added.
class SpotifyTrackMatch {
  const SpotifyTrackMatch({
    required this.trackId,
    required this.title,
    required this.artist,
    required this.confirmed,
    this.album,
  });

  factory SpotifyTrackMatch.fromMap(Map<String, Object?> map) =>
      SpotifyTrackMatch(
        trackId: map['trackId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        artist: map['artist'] as String? ?? '',
        album: map['album'] as String?,
        confirmed: map['confirmed'] as bool? ?? false,
      );

  final String trackId;
  final String title;
  final String artist;
  final String? album;
  final bool confirmed;
}

enum AddToPlaylistResult {
  added,
  alreadyInPlaylist;

  static AddToPlaylistResult parse(Object? value) =>
      value == 'already_in_playlist' ? alreadyInPlaylist : added;
}

/// Whether a song was added to a playlist, from the sync queue.
class PlaylistSyncItem {
  const PlaylistSyncItem({
    required this.playlistId,
    required this.status,
    this.playlistName,
    this.lastError,
  });

  factory PlaylistSyncItem.fromMap(Map<String, Object?> map) =>
      PlaylistSyncItem(
        playlistId: map['playlistId'] as String? ?? '',
        playlistName: map['playlistName'] as String?,
        status: map['status'] as String? ?? 'pending',
        lastError: map['lastError'] as String?,
      );

  final String playlistId;
  final String? playlistName;

  /// `pending`, `completed` or `failed`.
  final String status;
  final String? lastError;

  bool get completed => status == 'completed';
}
