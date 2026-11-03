import 'package:flutter/material.dart';

import 'haven_colors.dart';
import 'haven_spacing.dart';
import 'haven_text.dart';

/// The two themes the app ships.
///
/// Flat by construction: elevation is 0 everywhere, cards are separated by a
/// hairline divider rather than a shadow, and the only saturated colour is
/// [HavenColors.primary]. A parent on a low-end device sees the same layout a
/// parent on a flagship sees.
abstract final class HavenTheme {
  static ThemeData get light => _build(HavenColors.light, Brightness.light);

  static ThemeData get dark => _build(HavenColors.dark, Brightness.dark);

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final Color background = brightness == Brightness.light
        ? HavenColors.background
        : HavenColors.darkBackground;
    final Color textPrimary = brightness == Brightness.light
        ? HavenColors.textPrimary
        : HavenColors.darkTextPrimary;
    final Color textSecondary = brightness == Brightness.light
        ? HavenColors.textSecondary
        : HavenColors.darkTextSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashFactory: InkSparkle.splashFactory,
      textTheme: HavenText.textTheme(textPrimary, textSecondary),
      appBarTheme: AppBarThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: HavenText.headline.copyWith(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: HavenSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HavenRadius.md),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: HavenSpacing.gutter,
          vertical: HavenSpacing.xs,
        ),
        iconColor: textSecondary,
        titleTextStyle: HavenText.label.copyWith(color: textPrimary),
        subtitleTextStyle: HavenText.caption.copyWith(color: textSecondary),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surface,
        isDense: false,
        labelStyle: HavenText.label.copyWith(color: textSecondary),
        helperStyle: HavenText.caption.copyWith(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: HavenSpacing.md,
          vertical: HavenSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HavenRadius.sm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HavenRadius.sm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HavenRadius.sm),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.light
            ? HavenColors.textPrimary
            : HavenColors.darkSurface,
        contentTextStyle: HavenText.label.copyWith(color: background),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HavenRadius.sm),
        ),
      ),
      visualDensity: VisualDensity.standard,
    );
  }
}
