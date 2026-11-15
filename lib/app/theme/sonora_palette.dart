import 'package:material_ui/material_ui.dart';

/// Colour tokens for Sonora's Y2K pop look, in a light and a dark variant.
///
/// Read them with `context.palette` so every widget follows the chosen theme.
@immutable
class SonoraPalette extends ThemeExtension<SonoraPalette> {
  const SonoraPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.ink,
    required this.shadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.onAccent,
    required this.violet,
    required this.pink,
    required this.yellow,
    required this.teal,
    required this.orange,
    required this.success,
    required this.warning,
    required this.error,
  });

  /// Page background.
  final Color background;

  /// Card fill.
  final Color surface;

  /// Raised fill inside cards: chips, placeholders, inactive controls.
  final Color surfaceHigh;

  /// The sticker outline around cards and buttons.
  final Color ink;

  /// The hard offset shadow under stickers.
  final Color shadow;

  final Color textPrimary;
  final Color textSecondary;

  /// Lime: the main action colour.
  final Color accent;
  final Color onAccent;

  /// Pop colours, for chips and cover placeholders. Text on them is [onPop].
  final Color violet;
  final Color pink;
  final Color yellow;
  final Color teal;
  final Color orange;

  final Color success;
  final Color warning;
  final Color error;

  /// Dark text that reads on every pop colour, in both themes.
  Color get onPop => const Color(0xFF1B1030);

  /// A stable pop colour for [seed], so a song keeps its colour everywhere.
  Color popFor(int seed) {
    final colors = [pink, violet, yellow, teal, orange, accent];
    return colors[seed.abs() % colors.length];
  }

  static const light = SonoraPalette(
    background: Color(0xFFF3EEFF),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFEAE2FF),
    ink: Color(0xFF1B1030),
    shadow: Color(0xFF1B1030),
    textPrimary: Color(0xFF1B1030),
    textSecondary: Color(0xFF5E5378),
    accent: Color(0xFFC8F560),
    onAccent: Color(0xFF1B1030),
    violet: Color(0xFFA99BFF),
    pink: Color(0xFFFF8CC6),
    yellow: Color(0xFFFFE34D),
    teal: Color(0xFF5FD8C9),
    orange: Color(0xFFFFAD5C),
    success: Color(0xFF1C8A4C),
    warning: Color(0xFFA35F00),
    error: Color(0xFFD12E58),
  );

  static const dark = SonoraPalette(
    background: Color(0xFF110A1C),
    surface: Color(0xFF1D1430),
    surfaceHigh: Color(0xFF2B2043),
    ink: Color(0xFFE9E1FF),
    shadow: Color(0xFF7C66FF),
    textPrimary: Color(0xFFF6F1FF),
    textSecondary: Color(0xFFB7AAD8),
    accent: Color(0xFFC8F560),
    onAccent: Color(0xFF1B1030),
    violet: Color(0xFFA99BFF),
    pink: Color(0xFFFF8CC6),
    yellow: Color(0xFFFFE34D),
    teal: Color(0xFF5FD8C9),
    orange: Color(0xFFFFAD5C),
    success: Color(0xFF7BE3A6),
    warning: Color(0xFFFFC65C),
    error: Color(0xFFFF7D9A),
  );

  @override
  SonoraPalette copyWith() => this;

  @override
  SonoraPalette lerp(SonoraPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SonoraPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      ink: l(ink, other.ink),
      shadow: l(shadow, other.shadow),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      violet: l(violet, other.violet),
      pink: l(pink, other.pink),
      yellow: l(yellow, other.yellow),
      teal: l(teal, other.teal),
      orange: l(orange, other.orange),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      error: l(error, other.error),
    );
  }
}

extension SonoraPaletteContext on BuildContext {
  SonoraPalette get palette =>
      Theme.of(this).extension<SonoraPalette>() ?? SonoraPalette.dark;
}
