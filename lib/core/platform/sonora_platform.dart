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
