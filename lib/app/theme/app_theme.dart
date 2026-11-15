import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app_typography.dart';
import 'sonora_palette.dart';

/// Y2K pop: lilac and lime, sticker outlines, pill buttons.
abstract final class AppTheme {
  static ThemeData light() => _build(SonoraPalette.light, Brightness.light);

  static ThemeData dark() => _build(SonoraPalette.dark, Brightness.dark);

  static ThemeData _build(SonoraPalette p, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.violet,
          brightness: brightness,
        ).copyWith(
          primary: p.accent,
          onPrimary: p.onAccent,
          secondary: p.violet,
          onSecondary: p.onPop,
          surface: p.background,
          surfaceContainerLowest: p.surface,
          surfaceContainerLow: p.surface,
          surfaceContainer: p.surface,
          surfaceContainerHigh: p.surface,
          surfaceContainerHighest: p.surfaceHigh,
          onSurface: p.textPrimary,
          onSurfaceVariant: p.textSecondary,
          outline: p.ink,
          outlineVariant: p.ink.withValues(alpha: 0.18),
          error: p.error,
        );

    final base = ThemeData(
      colorScheme: scheme,
      brightness: brightness,
      useMaterial3: true,
    );

    final ink = BorderSide(color: p.ink, width: 2);
    final pill = WidgetStatePropertyAll<OutlinedBorder>(
      StadiumBorder(side: ink),
    );
    const buttonPadding = WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    );
    final buttonText = WidgetStatePropertyAll(
      base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
    );
    final overlay =
        (brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent);

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      extensions: [p],
      textTheme: AppTypography.textTheme(base.textTheme, p),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: overlay,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? p.surfaceHigh : p.accent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.disabled) ? p.textSecondary : p.onAccent,
          ),
          shape: pill,
          padding: buttonPadding,
          textStyle: buttonText,
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(p.textPrimary),
          backgroundColor: WidgetStatePropertyAll(p.surface),
          side: WidgetStatePropertyAll(ink),
          shape: pill,
          padding: buttonPadding,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(p.textPrimary),
          textStyle: buttonText,
          shape: const WidgetStatePropertyAll(StadiumBorder()),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(ink),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.accent : p.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.selected) ? p.onAccent : p.textPrimary,
          ),
          textStyle: buttonText,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onPop : p.ink,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.surfaceHigh,
        ),
        trackOutlineColor: WidgetStatePropertyAll(p.ink),
        trackOutlineWidth: const WidgetStatePropertyAll(2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: p.accent,
        indicatorShape: StadiumBorder(side: ink),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? p.onAccent
                : p.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => base.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: s.contains(WidgetState.selected)
                ? p.textPrimary
                : p.textSecondary,
          ),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(p.surface),
        side: WidgetStatePropertyAll(ink),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: ink,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          side: ink,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: ink,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: TextStyle(
          color: p.background,
          fontWeight: FontWeight.w700,
        ),
        shape: const StadiumBorder(),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.violet,
        linearTrackColor: p.surfaceHigh,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: ink,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: ink,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.violet, width: 3),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.ink.withValues(alpha: 0.15),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(iconColor: p.textSecondary),
    );
  }
}
