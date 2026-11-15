import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/sonora_palette.dart';
import '../../../recognition/recognition_error_copy.dart';
import '../providers/spotify_controller.dart';
import 'playlist_picker_sheet.dart';
import 'spotify_logo.dart';

/// Spotify connection and default playlist, for the Settings tab.
class SpotifyCard extends ConsumerWidget {
  const SpotifyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(spotifyControllerProvider);
    final controller = ref.read(spotifyControllerProvider.notifier);
    final status = state.status;
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: context.palette.textSecondary,
    );

    final children = <Widget>[
      Row(
        children: [
          const SpotifyLogo(),
          const SizedBox(width: 12),
          Text('Spotify', style: theme.textTheme.titleMedium),
        ],
      ),
      const SizedBox(height: 12),
    ];

    if (status == null) {
      children.add(const LinearProgressIndicator());
    } else if (!status.configured) {
      children.add(
        Text(
          recognitionErrorDetail('SPOTIFY_NOT_CONFIGURED')!,
          style: secondary,
        ),
      );
    } else if (!status.connected) {
      children.addAll([
        Text(
          'Connect your account to save recognised songs to a playlist. '
          'Sign-in happens on Spotify’s own page; Sonora never sees your password.',
          style: secondary,
        ),
        if (state.error != null) ...[
          const SizedBox(height: 8),
          Text(
            recognitionErrorDetail(state.error) ?? state.error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.palette.error,
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: state.busy ? null : controller.connect,
          icon: state.busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.link),
          label: Text(state.busy ? 'Waiting for Spotify…' : 'Connect Spotify'),
        ),
      ]);
    } else {
      children.addAll([
        Text(
          'Connected as ${status.displayName ?? 'your account'}',
          style: secondary,
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Save songs to'),
          subtitle: Text(status.defaultPlaylist?.name ?? 'Ask each time'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final picked = await showPlaylistPicker(context);
            if (picked != null) await controller.setDefaultPlaylist(picked);
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: state.busy ? null : controller.disconnect,
          child: const Text('Disconnect'),
        ),
      ]);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
