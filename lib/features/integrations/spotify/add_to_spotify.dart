import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/platform_failure.dart';
import '../../../core/models/spotify.dart';
import '../../../core/platform/sonora_platform.dart';
import '../../recognition/recognition_error_copy.dart';
import 'providers/spotify_controller.dart';
import 'widgets/playlist_picker_sheet.dart';

/// The manual "Add to playlist" flow for one history song:
/// connected? → playlist (default, or pick and remember) → Spotify track
/// (stored ID, or a search match the user confirms) → add exactly once.
Future<void> addSongToSpotify(
  BuildContext context,
  WidgetRef ref,
  int songId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  final spotify = ref.read(spotifyControllerProvider);
  if (!spotify.connected) {
    say('Connect Spotify in Settings to save songs to a playlist.');
    return;
  }

  SpotifyPlaylistRef? playlist = spotify.status?.defaultPlaylist;
  if (playlist == null) {
    final picked = await showPlaylistPicker(context);
    if (picked == null) return;
    playlist = picked;
    await ref
        .read(spotifyControllerProvider.notifier)
        .setDefaultPlaylist(picked);
  }

  final platform = ref.read(sonoraPlatformProvider);
  try {
    final match = await platform.findSpotifyTrack(songId);
    if (!match.confirmed) {
      if (!context.mounted) return;
      final ok = await _confirmMatch(context, match);
      if (ok != true) return;
    }
    final result = await platform.addToSpotifyPlaylist(
      songId: songId,
      playlist: playlist,
      trackId: match.trackId,
    );
    ref.invalidate(spotifySyncStatusProvider(songId));
    say(
      result == AddToPlaylistResult.added
          ? 'Added to ${playlist.name}'
          : 'Already in ${playlist.name}',
    );
  } on PlatformFailure catch (f) {
    ref.invalidate(spotifySyncStatusProvider(songId));
    say(recognitionErrorDetail(f.code) ?? f.message);
  }
}

Future<bool?> _confirmMatch(BuildContext context, SpotifyTrackMatch match) =>
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Is this the right song?'),
        content: Text(
          'Spotify’s best match is “${match.title}” by ${match.artist}'
          '${match.album == null ? '' : ', from ${match.album}'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, add it'),
          ),
        ],
      ),
    );
