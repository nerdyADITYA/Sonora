import 'package:material_ui/material_ui.dart';

import '../../app/theme/sonora_palette.dart';

/// A sticker-style card: thick outline, round corners and a hard offset shadow.
class PopCard extends StatelessWidget {
  const PopCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.shadowOffset = 4,
    this.onTap,
  });

  final Widget child;

  /// Fill colour. Defaults to the palette's surface.
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double shadowOffset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: p.ink, width: 2),
    );
    return Container(
      margin: EdgeInsets.only(right: shadowOffset, bottom: shadowOffset),
      // Shadow only: the Material below draws the outline, once.
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        shadows: [
          BoxShadow(
            color: p.shadow,
            offset: Offset(shadowOffset, shadowOffset),
          ),
        ],
      ),
      child: Material(
        color: color ?? p.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A small outlined pill label, like a sticker on a pin.
class PopChip extends StatelessWidget {
  const PopChip(this.label, {super.key, this.color, this.icon});

  final String label;

  /// Fill colour. Defaults to the palette's raised surface.
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fill = color ?? p.surfaceHigh;
    final text = color == null ? p.textPrimary : p.onPop;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: fill,
        shape: StadiumBorder(side: BorderSide(color: p.ink, width: 1.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: text, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Sonora's mark: five rounded waveform bars, as on the app icon.
class WaveformLogo extends StatelessWidget {
  const WaveformLogo({super.key, this.size = 28, this.color, this.highlight});

  final double size;
  final Color? color;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomPaint(
      size: Size.square(size),
      painter: _WaveformPainter(
        bars: color ?? p.violet,
        middle: highlight ?? p.textPrimary,
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({required this.bars, required this.middle});

  final Color bars;
  final Color middle;

  // Bar centres and tops/bottoms in the icon's 108-unit grid.
  static const _shape = [
    (28.0, 45.0, 63.0),
    (41.0, 34.0, 74.0),
    (54.0, 25.0, 83.0),
    (67.0, 37.0, 71.0),
    (80.0, 46.0, 62.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Map the 20..88 region of the grid onto the canvas.
    final scale = size.width / 68;
    for (final (i, (x, top, bottom)) in _shape.indexed) {
      final rect = Rect.fromLTRB(
        (x - 20 - 4) * scale,
        (top - 20) * scale,
        (x - 20 + 4) * scale,
        (bottom - 20) * scale,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(4 * scale)),
        Paint()..color = i == 2 ? middle : bars,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.bars != bars || old.middle != middle;
}

/// A big lowercase page title with optional actions, scrolling with the page.
class PopHeader extends StatelessWidget {
  const PopHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.actions = const [],
  });

  final String title;

  /// A small line above the title.
  final Widget? eyebrow;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null) ...[
                      eyebrow!,
                      const SizedBox(height: 14),
                    ],
                    Text(title, style: theme.textTheme.displaySmall),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

/// A small lowercase section label.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: context.palette.textSecondary),
    ),
  );
}
