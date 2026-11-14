import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Type scale. Uses the platform font (Roboto / One Sans on Samsung) rather than bundling one.
abstract final class AppTypography {
  static TextTheme textTheme(TextTheme base) => base
      .copyWith(
        displaySmall: base.displaySmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: base.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      )
      .apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      );
}
