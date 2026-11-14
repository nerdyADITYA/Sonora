import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/album_artwork.dart';
import '../../history/providers/history_providers.dart';
import '../../history/screens/song_detail_screen.dart';
import '../../recognition/providers/recognition_controller.dart';

/// The most recent recognition, read from history so it survives restarts.
class LastDiscoveryCard extends ConsumerWidget {
  const LastDiscoveryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final latest = ref.watch(latestRecognitionProvider).value;
    // A just-matched song shows immediately, before history reloads.
    final song =
        ref.watch(recognitionControllerProvider.select((s) => s.lastSong)) ??
        latest?.song;
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: latest == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SongDetailScreen(songId: latest.songId),
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LAST DISCOVERY',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  AlbumArtwork(
                    url: song?.artworkUrl,
                    highlighted: song != null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: song == null
                          ? [
                              Text(
                                'No songs yet',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Music Sonora recognises will appear here.',
                                style: secondary,
                              ),
                            ]
                          : [
                              Text(
                                song.title,
                                style: theme.textTheme.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                song.artist,
                                style: theme.textTheme.bodyLarge,
                              ),
                              if (song.album != null)
                                Text(
                                  song.album!,
                                  style: secondary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                    ),
                  ),
                ],
              ),
              if (song != null) ...[
                const SizedBox(height: 12),
                Text(
                  [
                    Formatting.dayAndTime(context, song.recognizedAt),
                    if (song.confidence != null)
                      'Confidence ${(song.confidence! * 100).round()}%',
                  ].join('  ·  '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
