import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';

/// Album cover with a music-note placeholder while loading, on error, or when
/// no artwork was found.
class AlbumArtwork extends StatelessWidget {
  const AlbumArtwork({
    super.key,
    this.url,
    this.highlighted = false,
    this.size = 88,
    this.radius = 14,
  });

  final String? url;
  final bool highlighted;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: highlighted ? AppColors.accent : AppColors.surfaceHigh,
      child: Icon(
        Icons.music_note_outlined,
        size: size * 0.4,
        color: highlighted ? AppColors.onAccent : AppColors.textSecondary,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
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
