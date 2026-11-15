import 'package:material_ui/material_ui.dart';

import 'sonora_palette.dart';

/// Chunky, tightly spaced type. Uses the platform font (One UI Sans on
/// Samsung) at heavy weights rather than bundling one.
abstract final class AppTypography {
  static TextTheme textTheme(TextTheme base, SonoraPalette palette) => base
      .copyWith(
        displaySmall: base.displaySmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          height: 1.0,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
          height: 1.05,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: base.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
        labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w800),
      )
      .apply(bodyColor: palette.textPrimary, displayColor: palette.textPrimary);
}
