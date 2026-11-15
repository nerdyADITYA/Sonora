import 'package:material_ui/material_ui.dart';

import '../../app/theme/sonora_palette.dart';
import 'pop.dart';

/// Album cover that fills its parent, with a coloured waveform placeholder
/// while loading, on error, or when no artwork was found.
class CoverFill extends StatelessWidget {
  const CoverFill({super.key, this.url, required this.color});

  final String? url;

  /// Placeholder fill.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: color,
      child: Center(
        child: LayoutBuilder(
          builder: (context, c) => WaveformLogo(
            size: c.biggest.shortestSide * 0.4,
            color: context.palette.onPop.withValues(alpha: 0.55),
            highlight: context.palette.onPop,
          ),
        ),
      ),
    );
    if (url == null) return placeholder;
    return Image.network(
      url!,
      key: ValueKey(url),
      fit: BoxFit.cover,
      semanticLabel: 'Album cover',
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
          frame == null && !wasSynchronouslyLoaded ? placeholder : child,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}

/// A square album cover with an outline.
class AlbumArtwork extends StatelessWidget {
  const AlbumArtwork({
    super.key,
    this.url,
    this.highlighted = false,
    this.size = 88,
    this.radius = 18,
    this.seed = 0,
  });

  final String? url;

  /// Uses the lime accent for the placeholder instead of a pop colour.
  final bool highlighted;
  final double size;
  final double radius;

  /// Picks the placeholder's pop colour, so a song keeps its colour.
  final int seed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: p.ink, width: 2),
    );
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(shape: shape),
      foregroundDecoration: ShapeDecoration(shape: shape),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CoverFill(
          url: url,
          color: highlighted ? p.accent : p.popFor(seed),
        ),
      ),
    );
  }
}
