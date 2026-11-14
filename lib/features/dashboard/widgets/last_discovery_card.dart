import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../listening/providers/listening_controller.dart';
import '../../recognition/providers/recognition_controller.dart';

/// The most recent match. Persistent history arrives in Phase 4.
class LastDiscoveryCard extends ConsumerWidget {
  const LastDiscoveryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Manual or ambient match this session, else the service's last match.
    final song =
        ref.watch(recognitionControllerProvider.select((s) => s.lastSong)) ??
        ref.watch(
          listeningControllerProvider.select((s) => s.status?.lastSong),
        );
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );

    return Card(
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
                AlbumArtwork(url: song?.artworkUrl, highlighted: song != null),
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
                            Text(song.artist, style: theme.textTheme.bodyLarge),
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
                  if (song.releaseDate != null) 'Released ${song.releaseDate}',
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
    );
  }
}

/// Album cover with a music-note placeholder while loading, on error, or when
/// no artwork was found.
class AlbumArtwork extends StatelessWidget {
  const AlbumArtwork({super.key, this.url, this.highlighted = false});

  static const size = 88.0;

  final String? url;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: highlighted ? AppColors.accent : AppColors.surfaceHigh,
      child: Icon(
        Icons.music_note_outlined,
        color: highlighted ? AppColors.onAccent : AppColors.textSecondary,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: url == null
          ? placeholder
          : Image.network(
              url!,
              key: ValueKey(url),
              width: size,
              height: size,
              fit: BoxFit.cover,
              semanticLabel: 'Album cover',
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                  frame == null && !wasSynchronouslyLoaded
                  ? placeholder
                  : child,
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
    );
  }
}
