import 'package:material_ui/material_ui.dart';

/// The Spotify icon (green circle, three black sound arcs), drawn as vectors
/// so it stays sharp at any size and needs no bundled image.
///
/// Spotify's brand guidelines ask for the icon in Spotify Green, black or
/// white, unmodified, next to content or actions that come from Spotify.
class SpotifyLogo extends StatelessWidget {
  const SpotifyLogo({super.key, this.size = 28});

  final double size;

  static const green = Color(0xFF1ED760);

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Spotify',
    image: true,
    child: CustomPaint(size: Size.square(size), painter: _SpotifyPainter()),
  );
}

class _SpotifyPainter extends CustomPainter {
  // Each arc: start, control point, end and stroke width, on a unit square.
  static const _arcs = [
    (Offset(0.215, 0.375), Offset(0.50, 0.255), Offset(0.79, 0.415), 0.090),
    (Offset(0.245, 0.525), Offset(0.49, 0.425), Offset(0.735, 0.555), 0.074),
    (Offset(0.27, 0.665), Offset(0.48, 0.590), Offset(0.69, 0.690), 0.058),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawCircle(
      Offset(s / 2, s / 2),
      s / 2,
      Paint()..color = SpotifyLogo.green,
    );
    for (final (start, control, end, width) in _arcs) {
      final path = Path()
        ..moveTo(start.dx * s, start.dy * s)
        ..quadraticBezierTo(
          control.dx * s,
          control.dy * s,
          end.dx * s,
          end.dy * s,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF000000)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width * s,
      );
    }
  }

  @override
  bool shouldRepaint(_SpotifyPainter oldDelegate) => false;
}
