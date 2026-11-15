import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants/channel_names.dart';
import '../../../core/errors/platform_failure.dart';
import '../../../core/models/listening_status.dart';
import '../../../core/models/recognized_song.dart';
import '../../../core/platform/sonora_platform.dart';

class ListeningState {
  const ListeningState({this.status, this.toggling = false, this.startError});

  /// Null until the first status arrives from native.
  final ListeningStatus? status;

  /// A start/stop request is in flight.
  final bool toggling;

  /// Why the last start attempt failed, if it did.
  final String? startError;

  bool get listening => status?.listening ?? false;

  ListeningState copyWith({
    ListeningStatus? status,
    bool? toggling,
    String? startError,
    bool clearStartError = false,
  }) => ListeningState(
    status: status ?? this.status,
    toggling: toggling ?? this.toggling,
    startError: clearStartError ? null : (startError ?? this.startError),
  );
}

abstract final class ListeningErrors {
  static const permissionDenied = 'PERMISSION_DENIED';
  static const permissionPermanentlyDenied = 'PERMISSION_PERMANENTLY_DENIED';
}

final listeningControllerProvider =
    NotifierProvider<ListeningController, ListeningState>(
      ListeningController.new,
    );

/// Mirrors the native listening service and starts/stops it.
class ListeningController extends Notifier<ListeningState> {
  @override
  ListeningState build() {
    final platform = ref.watch(sonoraPlatformProvider);

    final subscription = platform.events.listen((event) {
      if (event.type == BridgeEventTypes.listeningStatus) {
        state = state.copyWith(status: ListeningStatus.fromMap(event.data));
      }
    }, onError: (Object _) {});

    // Events are missed while the Flutter engine is paused; resync on resume.
    final lifecycle = AppLifecycleListener(onResume: refresh);

    ref.onDispose(() {
      subscription.cancel();
      lifecycle.dispose();
    });

    Future.microtask(refresh);
    return const ListeningState();
  }

  SonoraPlatform get _platform => ref.read(sonoraPlatformProvider);

  Future<void> refresh() async {
    try {
      final status = await _platform.getListeningStatus();
      state = state.copyWith(status: status);
    } on PlatformFailure {
      // Leave the last known status in place.
    }
  }

  Future<void> start() async {
    if (state.toggling || state.listening) return;
    state = state.copyWith(toggling: true, clearStartError: true);
    try {
      final permission = await _platform.requestMicrophonePermission();
      if (permission != MicrophonePermission.granted) {
        state = state.copyWith(
          toggling: false,
          startError: permission == MicrophonePermission.permanentlyDenied
              ? ListeningErrors.permissionPermanentlyDenied
              : ListeningErrors.permissionDenied,
        );
        return;
      }
      final status = await _platform.startListening();
      state = state.copyWith(status: status, toggling: false);
    } on PlatformFailure catch (failure) {
      state = state.copyWith(toggling: false, startError: failure.code);
    }
  }

  /// Hides the "listening was stopped" notice without restarting.
  Future<void> dismissInterruption() async {
    try {
      state = state.copyWith(
        status: await _platform.dismissListeningInterruption(),
      );
    } on PlatformFailure {
      // Shown again next time; harmless.
    }
  }

  Future<void> openBatterySettings() async {
    try {
      await _platform.openBatterySettings();
    } on PlatformFailure {
      // Nothing to open; the copy still explains where the setting is.
    }
  }

  Future<void> stop() async {
    if (state.toggling) return;
    state = state.copyWith(toggling: true, clearStartError: true);
    try {
      await _platform.stopListening();
      state = state.copyWith(status: ListeningStatus.stopped, toggling: false);
    } on PlatformFailure catch (failure) {
      state = state.copyWith(toggling: false, startError: failure.code);
    }
  }
}
