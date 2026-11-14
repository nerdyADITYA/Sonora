import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/channel_names.dart';
import '../../../../core/errors/platform_failure.dart';
import '../../../../core/models/spotify.dart';
import '../../../../core/platform/sonora_platform.dart';

class SpotifyState {
  const SpotifyState({this.status, this.busy = false, this.error});

  /// Null until the first status arrives from native.
  final SpotifyStatus? status;

  /// Waiting for the browser sign-in or a disconnect to finish.
  final bool busy;

  /// Error code from the last connect attempt.
  final String? error;

  bool get connected => status?.connected ?? false;
}

final spotifyControllerProvider =
    NotifierProvider<SpotifyController, SpotifyState>(SpotifyController.new);

/// Mirrors the native Spotify connection. Sign-in finishes in the browser and
/// comes back as a `spotify_status` event.
class SpotifyController extends Notifier<SpotifyState> {
  @override
  SpotifyState build() {
    final platform = ref.watch(sonoraPlatformProvider);
    final subscription = platform.events
        .where((e) => e.type == BridgeEventTypes.spotifyStatus)
        .listen((event) {
          final status = SpotifyStatus.fromMap(event.data);
          state = SpotifyState(status: status, error: status.error);
          if (status.connected) unawaited(_retryQueue());
        }, onError: (Object _) {});

    // Returning from the browser without completing sign-in leaves `busy`
    // set; resync on resume. Failed playlist adds are retried here too.
    final lifecycle = AppLifecycleListener(onResume: refresh);
    ref.onDispose(() {
      subscription.cancel();
      lifecycle.dispose();
    });

    Future.microtask(refresh);
    return const SpotifyState();
  }

  SonoraPlatform get _platform => ref.read(sonoraPlatformProvider);

  Future<void> refresh() async {
    try {
      final status = await _platform.getSpotifyStatus();
      state = SpotifyState(status: status, error: state.error);
      if (status.connected) unawaited(_retryQueue());
    } on PlatformFailure {
      // Keep the last known state.
    }
  }

  Future<void> connect() async {
    state = SpotifyState(status: state.status, busy: true);
    try {
      await _platform.connectSpotify();
    } on PlatformFailure catch (f) {
      state = SpotifyState(status: state.status, error: f.code);
    }
  }

  Future<void> disconnect() async {
    state = SpotifyState(status: state.status, busy: true);
    try {
      state = SpotifyState(status: await _platform.disconnectSpotify());
    } on PlatformFailure catch (f) {
      state = SpotifyState(status: state.status, error: f.code);
    }
  }

  Future<void> setDefaultPlaylist(SpotifyPlaylistRef playlist) async {
    state = SpotifyState(
      status: await _platform.setDefaultSpotifyPlaylist(playlist),
    );
  }

  Future<void> _retryQueue() async {
    try {
      await _platform.retrySpotifySync();
    } on PlatformFailure {
      // Retried again on the next resume.
    }
  }
}

/// The user's editable playlists; reloaded each time a picker opens.
final spotifyPlaylistsProvider =
    FutureProvider.autoDispose<SpotifyPlaylistPage>(
      (ref) => ref.watch(sonoraPlatformProvider).getSpotifyPlaylists(),
    );

/// Which playlists a song was added to.
final spotifySyncStatusProvider = FutureProvider.autoDispose
    .family<List<PlaylistSyncItem>, int>(
      (ref, songId) =>
          ref.watch(sonoraPlatformProvider).getSpotifySyncStatus(songId),
    );
