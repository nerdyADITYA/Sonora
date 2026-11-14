import 'dart:async';

import 'package:sonora/core/errors/platform_failure.dart';
import 'package:sonora/core/models/history.dart';
import 'package:sonora/core/models/listening_status.dart';
import 'package:sonora/core/models/platform_info.dart';
import 'package:sonora/core/models/recognized_song.dart';
import 'package:sonora/core/models/sonora_event.dart';
import 'package:sonora/core/platform/sonora_platform.dart';

/// Stands in for the Kotlin bridge in widget tests.
class FakePlatform extends SonoraPlatform {
  FakePlatform({
    this.failInfo = false,
    this.permission = MicrophonePermission.granted,
    this.attempt,
    this.recognitionFailure,
  });

  final bool failInfo;
  final MicrophonePermission permission;
  final RecognitionAttempt? attempt;
  final PlatformFailure? recognitionFailure;

  @override
  Future<PlatformInfo> getPlatformInfo() async {
    if (failInfo) throw const PlatformFailure.unavailable();
    return const PlatformInfo(
      manufacturer: 'samsung',
      brand: 'samsung',
      model: 'SM-S928B',
      device: 'e3q',
      androidVersion: '17',
      sdkInt: 37,
      securityPatch: '2026-11-01',
      isSamsung: true,
      appVersion: '0.1.0',
    );
  }

  final _events = StreamController<SonoraEvent>.broadcast();
  ListeningStatus _status = ListeningStatus.stopped;

  void emit(String type, Map<String, Object?> data) => _events.add(
    SonoraEvent(type: type, timestamp: DateTime(2026), data: data),
  );

  @override
  Future<ListeningStatus> getListeningStatus() async => _status;

  @override
  Future<ListeningStatus> startListening() async => _status = ListeningStatus(
    listening: true,
    available: true,
    phase: ListeningPhase.waiting,
    nextCheckAt: DateTime(2026, 11, 14, 18, 30),
    requestsToday: 3,
    dailyBudget: 200,
  );

  @override
  Future<void> stopListening() async => _status = ListeningStatus.stopped;

  @override
  Future<MicrophonePermission> requestMicrophonePermission() async =>
      permission;

  @override
  Future<RecognitionAttempt> recognizeOnce() async {
    if (recognitionFailure != null) throw recognitionFailure!;
    return attempt ??
        const RecognitionAttempt(song: null, elapsed: Duration(seconds: 10));
  }

  /// In-memory history, newest first, mimicking the native repository.
  final List<HistoryEntry> history = [];

  void addHistory(HistoryEntry entry) {
    history.insert(0, entry);
    emit('history_changed', const {});
  }

  @override
  Future<HistoryPage> getRecognitionHistory({
    String? query,
    HistorySort sort = HistorySort.newest,
    int limit = 200,
  }) async {
    final q = query?.toLowerCase();
    final matches = history.where(
      (e) =>
          q == null ||
          e.song.title.toLowerCase().contains(q) ||
          e.song.artist.toLowerCase().contains(q),
    );
    return HistoryPage(
      entries: matches.take(limit).toList(),
      total: history.length,
    );
  }

  @override
  Future<SongDetail> getSongDetail(int songId) async {
    final entries = history.where((e) => e.songId == songId).toList();
    if (entries.isEmpty) throw const PlatformFailure('NOT_FOUND', 'Gone');
    return SongDetail(
      songId: songId,
      song: entries.first.song,
      firstHeardAt: entries.last.recognizedAt,
      recognitions: entries,
    );
  }

  @override
  Future<void> deleteRecognition(int eventId) async {
    history.removeWhere((e) => e.eventId == eventId);
    emit('history_changed', const {});
  }

  @override
  Future<void> deleteSong(int songId) async {
    history.removeWhere((e) => e.songId == songId);
    emit('history_changed', const {});
  }

  @override
  Future<void> clearRecognitionHistory() async {
    history.clear();
    emit('history_changed', const {});
  }

  @override
  Stream<SonoraEvent> get events async* {
    yield SonoraEvent(type: 'bridge_connected', timestamp: DateTime(2026));
    yield* _events.stream;
  }
}
