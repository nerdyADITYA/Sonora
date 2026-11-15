import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/channel_names.dart';
import '../errors/platform_failure.dart';
import '../models/bridge_response.dart';
import '../models/history.dart';
import '../models/listening_status.dart';
import '../models/platform_info.dart';
import '../models/recognized_song.dart';
import '../models/sonora_event.dart';
import '../models/spotify.dart';

final sonoraPlatformProvider = Provider<SonoraPlatform>(
  (ref) => SonoraPlatform(),
);

/// The only place Dart talks to the Kotlin bridge. Features use this through
/// providers, never the channels directly.
class SonoraPlatform {
  SonoraPlatform({MethodChannel? control, EventChannel? events})
    : _control = control ?? const MethodChannel(ChannelNames.control),
      _eventsChannel = events ?? const EventChannel(ChannelNames.events);

  final MethodChannel _control;
  final EventChannel _eventsChannel;
  Stream<SonoraEvent>? _events;

  Future<PlatformInfo> getPlatformInfo() async =>
      PlatformInfo.fromMap(await _invoke(BridgeMethods.getPlatformInfo));

  Future<ListeningStatus> getListeningStatus() async =>
      ListeningStatus.fromMap(await _invoke(BridgeMethods.getListeningStatus));

  /// Shows the system microphone prompt if needed.
  Future<MicrophonePermission> requestMicrophonePermission() async {
    final data = await _invoke(BridgeMethods.requestPermissions);
    return MicrophonePermission.parse(data['microphone']);
  }

  /// Captures about 10 s of audio and identifies it. Throws [PlatformFailure] on errors.
  Future<RecognitionAttempt> recognizeOnce() async =>
      RecognitionAttempt.fromMap(await _invoke(BridgeMethods.recognizeOnce));

  Future<void> cancelRecognition() async {
    await _invoke(BridgeMethods.cancelRecognition);
  }

  /// Starts the microphone foreground service. Call only while the app is visible.
  Future<ListeningStatus> startListening() async =>
      ListeningStatus.fromMap(await _invoke(BridgeMethods.startListening));

  Future<void> stopListening() async {
    await _invoke(BridgeMethods.stopListening);
  }

  Future<HistoryPage> getRecognitionHistory({
    String? query,
    HistorySort sort = HistorySort.newest,
    int limit = 200,
  }) async => HistoryPage.fromMap(
    await _invoke(BridgeMethods.getRecognitionHistory, {
      'query': query,
      'sort': sort.wire,
      'limit': limit,
    }),
  );

  /// Throws [PlatformFailure] with code `NOT_FOUND` if the song was deleted.
  Future<SongDetail> getSongDetail(int songId) async => SongDetail.fromMap(
    await _invoke(BridgeMethods.getSongDetail, {'songId': songId}),
  );

  Future<void> deleteRecognition(int eventId) async {
    await _invoke(BridgeMethods.deleteRecognition, {'eventId': eventId});
  }

  Future<void> deleteSong(int songId) async {
    await _invoke(BridgeMethods.deleteSong, {'songId': songId});
  }

  Future<void> clearRecognitionHistory() async {
    await _invoke(BridgeMethods.clearRecognitionHistory);
  }

  /// Shows [song] in Spotify's search (or the browser) without starting playback.
  Future<void> openInSpotify(RecognizedSong song) async {
    await _invoke(BridgeMethods.openInSpotify, {
      'title': song.title,
      'artist': song.artist,
    });
  }

  Future<SpotifyStatus> getSpotifyStatus() async =>
      SpotifyStatus.fromMap(await _invoke(BridgeMethods.getSpotifyStatus));

  /// Opens Spotify's sign-in page in the browser. The outcome arrives later
  /// as a `spotify_status` event, after the redirect back to Sonora.
  Future<void> connectSpotify() async {
    await _invoke(BridgeMethods.connectSpotify);
  }

  Future<SpotifyStatus> disconnectSpotify() async =>
      SpotifyStatus.fromMap(await _invoke(BridgeMethods.disconnectSpotify));

  /// Playlists the user owns or collaborates on.
  Future<SpotifyPlaylistPage> getSpotifyPlaylists() async {
    final data = await _invoke(BridgeMethods.getSpotifyPlaylists);
    return SpotifyPlaylistPage(
      playlists: [
        for (final p in data['playlists'] as List? ?? const [])
          SpotifyPlaylist.fromMap((p as Map).cast<String, Object?>()),
      ],
      hiddenCount: (data['hiddenCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<SpotifyPlaylist> createSpotifyPlaylist(String name) async =>
      SpotifyPlaylist.fromMap(
        await _invoke(BridgeMethods.createSpotifyPlaylist, {'name': name}),
      );

  Future<SpotifyStatus> setDefaultSpotifyPlaylist(
    SpotifyPlaylistRef playlist,
  ) async => SpotifyStatus.fromMap(
    await _invoke(BridgeMethods.setDefaultSpotifyPlaylist, {
      'id': playlist.id,
      'name': playlist.name,
    }),
  );

  Future<SpotifyTrackMatch> findSpotifyTrack(int songId) async =>
      SpotifyTrackMatch.fromMap(
        await _invoke(BridgeMethods.findSpotifyTrack, {'songId': songId}),
      );

  /// Adds the song once; a repeat returns [AddToPlaylistResult.alreadyInPlaylist].
  /// [trackId] is needed only for a search match the user confirmed.
  Future<AddToPlaylistResult> addToSpotifyPlaylist({
    required int songId,
    required SpotifyPlaylistRef playlist,
    String? trackId,
  }) async {
    final data = await _invoke(BridgeMethods.addToSpotifyPlaylist, {
      'songId': songId,
      'playlistId': playlist.id,
      'playlistName': playlist.name,
      'trackId': trackId,
    });
    return AddToPlaylistResult.parse(data['result']);
  }

  Future<List<PlaylistSyncItem>> getSpotifySyncStatus(int songId) async {
    final data = await _invoke(BridgeMethods.getSpotifySyncStatus, {
      'songId': songId,
    });
    return [
      for (final i in data['items'] as List? ?? const [])
        PlaylistSyncItem.fromMap((i as Map).cast<String, Object?>()),
    ];
  }

  /// Retries adds that failed earlier; returns how many succeeded.
  Future<int> retrySpotifySync() async {
    final data = await _invoke(BridgeMethods.retrySpotifySync);
    return (data['retried'] as num?)?.toInt() ?? 0;
  }

  /// Opens Sonora's app info, where One UI keeps the Battery setting.
  Future<void> openBatterySettings() async {
    await _invoke(BridgeMethods.openBatterySettings);
  }

  /// Clears the "listening was stopped" notice.
  Future<ListeningStatus> dismissListeningInterruption() async =>
      ListeningStatus.fromMap(
        await _invoke(BridgeMethods.dismissListeningInterruption),
      );

  /// Asks Android to add the Quick Settings tile. Returns `added`,
  /// `already_added`, `not_added`, `unavailable` or `unsupported`.
  Future<String> requestAddTile() async {
    final data = await _invoke(BridgeMethods.requestAddTile);
    return data['result'] as String? ?? 'unavailable';
  }

  /// The song the notification opened the app for, once.
  Future<int?> takeLaunchSongId() async {
    final data = await _invoke(BridgeMethods.takeLaunchSongId);
    return (data['songId'] as num?)?.toInt();
  }

  /// Broadcast stream of native events; safe to listen to more than once.
  Stream<SonoraEvent> get events => _events ??= _eventsChannel
      .receiveBroadcastStream()
      .map(SonoraEvent.fromNative);

  Future<Map<String, Object?>> _invoke(
    String method, [
    Object? arguments,
  ]) async {
    final Object? raw;
    try {
      raw = await _control.invokeMethod<Object?>(method, arguments);
    } on MissingPluginException {
      throw const PlatformFailure.unavailable();
    } on PlatformException catch (e) {
      throw PlatformFailure(e.code, e.message ?? 'Native call failed.');
    }
    return unwrapBridgeResponse(raw);
  }
}
