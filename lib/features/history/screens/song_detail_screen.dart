import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/platform_failure.dart';
import '../../../core/models/history.dart';
import '../../../core/models/recognized_song.dart';
import '../../../core/platform/sonora_platform.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/album_artwork.dart';
import '../providers/history_providers.dart';

/// One song: cover, metadata, and every time it was heard.
class SongDetailScreen extends ConsumerWidget {
  const SongDetailScreen({super.key, required this.songId});

  final int songId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SongDetail detail,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this song?'),
        content: Text(
          'Removes “${detail.song.title}” and all ${detail.timesHeard} '
          '${detail.timesHeard == 1 ? 'recognition' : 'recognitions'} from your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(sonoraPlatformProvider).deleteSong(songId);
      if (context.mounted) Navigator.of(context).pop();
    } on PlatformFailure {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't delete that song")),
        );
      }
    }
  }

  Future<void> _openInSpotify(
    BuildContext context,
    WidgetRef ref,
    RecognizedSong song,
  ) async {
    try {
      await ref.read(sonoraPlatformProvider).openInSpotify(song);
    } on PlatformFailure {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Couldn't open Spotify")));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(songDetailProvider(songId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (detail.value case final d?)
            IconButton(
              tooltip: 'Delete song',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref, d),
            ),
        ],
      ),
      body: switch (detail) {
        AsyncData(:final value) => _body(context, ref, value),
        AsyncError(:final error) => Center(
          child: Text(
            error is PlatformFailure && error.code == 'NOT_FOUND'
                ? 'This song is no longer in your history.'
                : "Couldn't load this song.",
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, SongDetail detail) {
    final theme = Theme.of(context);
    final song = detail.song;
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Center(
          child: AlbumArtwork(
            url: song.artworkUrl,
            highlighted: true,
            size: 240,
            radius: 24,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          song.title,
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          song.artist,
          style: theme.textTheme.titleMedium?.copyWith(color: AppColors.accent),
          textAlign: TextAlign.center,
        ),
        if (song.album != null) ...[
          const SizedBox(height: 4),
          Text(song.album!, style: secondary, textAlign: TextAlign.center),
        ],
        if (song.spotifyTrackId != null) ...[
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: () => _openInSpotify(context, ref, song),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in Spotify'),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                _InfoRow(
                  'First heard',
                  Formatting.dayAndTime(context, detail.firstHeardAt),
                ),
                _InfoRow('Times heard', '${detail.timesHeard}'),
                if (song.releaseDate != null)
                  _InfoRow('Released', song.releaseDate!),
                if (song.durationMs != null)
                  _InfoRow('Length', Formatting.duration(song.durationMs!)),
                if (song.isrc != null) _InfoRow('ISRC', song.isrc!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'HEARD',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        for (final r in detail.recognitions)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              r.source == RecognitionSource.ambient
                  ? Icons.graphic_eq
                  : Icons.touch_app_outlined,
              color: AppColors.textSecondary,
            ),
            title: Text(Formatting.dayAndTime(context, r.recognizedAt)),
            subtitle: Text(
              [
                r.source == RecognitionSource.ambient
                    ? 'Ambient listening'
                    : 'Identified manually',
                if (r.song.confidence != null)
                  'Confidence ${(r.song.confidence! * 100).round()}%',
              ].join(' · '),
              style: secondary,
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
