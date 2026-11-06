import 'package:flutter/material.dart';

import 'child_colors.dart';
import 'child_spacing.dart';
import 'child_text.dart';

/// The two themes the child app ships — the parent's flat design language,
/// owned by this app.
///
/// Flat by construction: elevation is 0 everywhere, cards are separated by a
/// hairline divider rather than a shadow, and the only saturated colour is
/// [ChildColors.primary]. A child on a low-end device sees the same layout
/// the parent sees on a flagship.
abstract final class ChildTheme {
  static ThemeData get light => _build(ChildColors.light, Brightness.light);

  static ThemeData get dark => _build(ChildColors.dark, Brightness.dark);

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final Color background = brightness == Brightness.light
        ? ChildColors.background
        : ChildColors.darkBackground;
    final Color textPrimary = brightness == Brightness.light
        ? ChildColors.textPrimary
        : ChildColors.darkTextPrimary;
    final Color textSecondary = brightness == Brightness.light
        ? ChildColors.textSecondary
        : ChildColors.darkTextSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: ChildText.textTheme(textPrimary, textSecondary),
      appBarTheme: AppBarThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: ChildText.headline.copyWith(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: ChildSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChildRadius.md),
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
          horizontal: ChildSpacing.gutter,
          vertical: ChildSpacing.xs,
        ),
        iconColor: textSecondary,
        titleTextStyle: ChildText.label.copyWith(color: textPrimary),
        subtitleTextStyle: ChildText.caption.copyWith(color: textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.light
            ? ChildColors.textPrimary
            : ChildColors.darkSurface,
        contentTextStyle: ChildText.label.copyWith(color: background),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChildRadius.sm),
        ),
      ),
      visualDensity: VisualDensity.standard,
    );
  }
}
