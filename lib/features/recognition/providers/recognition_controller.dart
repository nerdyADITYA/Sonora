import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/channel_names.dart';
import '../../../core/errors/platform_failure.dart';
import '../../../core/models/recognized_song.dart';
import '../../../core/platform/sonora_platform.dart';

enum RecognitionPhase {
  idle,
  requestingPermission,
  capturing,
  matching,
  matched,
  noMatch,
  failed,
}

class RecognitionState {
  const RecognitionState({
    this.phase = RecognitionPhase.idle,
    this.lastSong,
    this.errorCode,
    this.elapsed,
    this.confident = true,
  });

  final RecognitionPhase phase;

  /// Most recent match this session. Persisted history arrives in Phase 4.
  final RecognizedSong? lastSong;

  /// A [PlatformFailure] code, or `PERMISSION_DENIED` / `PERMISSION_PERMANENTLY_DENIED`.
  final String? errorCode;
  final Duration? elapsed;

  /// False when the last match had a low score.
  final bool confident;

  bool get isBusy => switch (phase) {
    RecognitionPhase.requestingPermission ||
    RecognitionPhase.capturing ||
    RecognitionPhase.matching => true,
    _ => false,
  };

  RecognitionState next(
    RecognitionPhase phase, {
    RecognizedSong? song,
    String? errorCode,
    Duration? elapsed,
    bool confident = true,
  }) => RecognitionState(
    phase: phase,
    lastSong: song ?? lastSong,
    errorCode: errorCode,
    elapsed: elapsed,
    confident: confident,
  );
}

abstract final class RecognitionErrors {
  static const permissionDenied = 'PERMISSION_DENIED';
  static const permissionPermanentlyDenied = 'PERMISSION_PERMANENTLY_DENIED';
}

final recognitionControllerProvider =
    NotifierProvider<RecognitionController, RecognitionState>(
      RecognitionController.new,
    );

/// Drives manual, user-initiated recognition (Phase 2).
class RecognitionController extends Notifier<RecognitionState> {
  @override
  RecognitionState build() {
    final subscription = ref.watch(sonoraPlatformProvider).events.listen((
      event,
    ) {
      switch (event.type) {
        // Songs found by ambient listening become the last discovery too.
        case BridgeEventTypes.songRecognized:
          state = RecognitionState(
            phase: state.phase,
            lastSong: RecognizedSong.fromMap(event.data),
            errorCode: state.errorCode,
            elapsed: state.elapsed,
          );
        case BridgeEventTypes.recognitionCapturing when state.isBusy:
          state = state.next(RecognitionPhase.capturing);
        case BridgeEventTypes.recognitionMatching when state.isBusy:
          state = state.next(RecognitionPhase.matching);
      }
    }, onError: (Object _) {});
    ref.onDispose(subscription.cancel);
    return const RecognitionState();
  }

  SonoraPlatform get _platform => ref.read(sonoraPlatformProvider);

  Future<void> recognize() async {
    if (state.isBusy) return;
    state = state.next(RecognitionPhase.requestingPermission);

    try {
      final permission = await _platform.requestMicrophonePermission();
      if (permission != MicrophonePermission.granted) {
        state = state.next(
          RecognitionPhase.failed,
          errorCode: permission == MicrophonePermission.permanentlyDenied
              ? RecognitionErrors.permissionPermanentlyDenied
              : RecognitionErrors.permissionDenied,
        );
        return;
      }

      state = state.next(RecognitionPhase.capturing);
      final attempt = await _platform.recognizeOnce();
      state = attempt.matched
          ? state.next(
              RecognitionPhase.matched,
              song: attempt.song,
              elapsed: attempt.elapsed,
              confident: attempt.confident,
            )
          : state.next(RecognitionPhase.noMatch, elapsed: attempt.elapsed);
    } on PlatformFailure catch (failure) {
      state = state.next(RecognitionPhase.failed, errorCode: failure.code);
    }
  }

  Future<void> cancel() async {
    if (!state.isBusy) return;
    try {
      await _platform.cancelRecognition();
    } on PlatformFailure {
      // The pending recognizeOnce call still resolves (as CANCELLED).
    }
  }
}
