import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/sonora_palette.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/album_artwork.dart';
import '../../../shared/widgets/pop.dart';
import '../../history/providers/history_providers.dart';
import '../../history/screens/song_detail_screen.dart';
import '../../recognition/providers/recognition_controller.dart';

/// The most recent recognition as a big pin, read from history so it
/// survives restarts.
class LastDiscoveryCard extends ConsumerWidget {
  const LastDiscoveryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = context.palette;
    final latest = ref.watch(latestRecognitionProvider).value;
    // A just-matched song shows immediately, before history reloads.
    final song =
        ref.watch(recognitionControllerProvider.select((s) => s.lastSong)) ??
        latest?.song;

    if (song == null) {
      return PopCard(
        color: p.surfaceHigh,
        child: Row(
          children: [
            const AlbumArtwork(size: 64, radius: 16, seed: 1),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No songs yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Music Sonora recognises will appear here.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final fresh =
        DateTime.now().difference(song.recognizedAt) < const Duration(hours: 1);

    return PopCard(
      padding: EdgeInsets.zero,
      onTap: latest == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SongDetailScreen(songId: latest.songId),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.5,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: p.ink, width: 2)),
              ),
              child: CoverFill(
                url: song.artworkUrl,
                color: p.popFor(latest?.songId ?? 0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: theme.textTheme.headlineSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  song.artist,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (song.album != null)
                  Text(
                    song.album!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: p.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (fresh) PopChip('new', color: p.yellow),
                    PopChip(
                      Formatting.dayAndTime(context, song.recognizedAt),
                      icon: Icons.schedule,
                    ),
                    if (song.confidence != null)
                      PopChip(
                        'Confidence ${(song.confidence! * 100).round()}%',
                        color: p.teal,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
