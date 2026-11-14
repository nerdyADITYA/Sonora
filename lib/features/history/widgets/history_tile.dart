import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/history.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/album_artwork.dart';
import '../screens/song_detail_screen.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final song = entry.song;
    final ambient = entry.source == RecognitionSource.ambient;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: AlbumArtwork(url: song.artworkUrl, size: 52, radius: 10),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatting.time(context, entry.recognizedAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            ambient ? Icons.graphic_eq : Icons.touch_app_outlined,
            size: 16,
            color: AppColors.textSecondary,
            semanticLabel: ambient
                ? 'Heard by ambient listening'
                : 'Identified manually',
          ),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SongDetailScreen(songId: entry.songId),
        ),
      ),
    );
  }
}
