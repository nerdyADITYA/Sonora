import 'package:material_ui/material_ui.dart';

import '../../app/theme/sonora_palette.dart';
import '../../core/models/history.dart';
import '../../features/history/screens/song_detail_screen.dart';
import '../utils/formatting.dart';
import 'album_artwork.dart';

/// A two-column masonry layout: each child goes into the shorter column.
class Masonry extends StatelessWidget {
  const Masonry({
    super.key,
    required this.children,
    required this.heights,
    this.spacing = 12,
  });

  final List<Widget> children;

  /// A rough relative height for each child, used to balance the columns.
  final List<double> heights;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final columns = [<Widget>[], <Widget>[]];
    final totals = [0.0, 0.0];
    for (var i = 0; i < children.length; i++) {
      final c = totals[0] <= totals[1] ? 0 : 1;
      if (columns[c].isNotEmpty) columns[c].add(SizedBox(height: spacing));
      columns[c].add(children[i]);
      totals[c] += heights[i];
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: columns[0])),
        SizedBox(width: spacing),
        Expanded(child: Column(children: columns[1])),
      ],
    );
  }
}

/// Cover shapes for pins, picked per recognition so the board looks varied
/// but never reshuffles.
const _aspects = [1.0, 0.78, 1.18, 0.9, 0.7, 1.08];

double pinAspect(HistoryEntry entry) =>
    _aspects[entry.eventId.abs() % _aspects.length];

/// Relative height of a pin, for [Masonry]: the cover plus the caption.
double pinHeight(HistoryEntry entry) => 1 / pinAspect(entry) + 0.45;

/// One recognition as a Pinterest-style pin: cover, title, artist, when.
class PinCard extends StatelessWidget {
  const PinCard({super.key, required this.entry, this.showDay = false});

  final HistoryEntry entry;

  /// Shows the day as well as the time, for boards that aren't grouped by day.
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    final song = entry.song;
    final ambient = entry.source == RecognitionSource.ambient;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: BorderSide(color: p.ink, width: 2),
    );

    return Material(
      color: p.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SongDetailScreen(songId: entry.songId),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: pinAspect(entry),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: p.ink, width: 2)),
                ),
                child: CoverFill(
                  url: song.artworkUrl,
                  color: p.popFor(entry.songId),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        ambient ? Icons.graphic_eq : Icons.touch_app_outlined,
                        size: 14,
                        color: p.textSecondary,
                        semanticLabel: ambient
                            ? 'Heard by ambient listening'
                            : 'Identified manually',
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          showDay
                              ? Formatting.dayAndTime(
                                  context,
                                  entry.recognizedAt,
                                )
                              : Formatting.time(context, entry.recognizedAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: p.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
