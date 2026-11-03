import 'package:flutter/material.dart';

/// Haven's colour vocabulary. One accent, flat surfaces, no gradients.
///
/// Pairings are checked against WCAG AA for normal text: the label colour that
/// sits on each background is named next to it, so a screen cannot accidentally
/// pair `textSecondary` with `background` and drop below contrast.
abstract final class HavenColors {
  static const Color primary = Color(0xFF0F6B5F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF6F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF16211F);
  static const Color textSecondary = Color(0xFF4C5856);
  static const Color outline = Color(0xFFC7CECB);

  static const Color good = Color(0xFF1B6B42);
  static const Color warning = Color(0xFF7A4F01);
  static const Color bad = Color(0xFFA01D19);

  /// "Not specified yet" — deliberately not red: a blocked feature is not an error.
  static const Color blocked = Color(0xFF4A4750);

  static const Color darkPrimary = Color(0xFF7AD6C6);
  static const Color darkOnPrimary = Color(0xFF052E29);
  static const Color darkBackground = Color(0xFF101413);
  static const Color darkSurface = Color(0xFF181E1D);
  static const Color darkTextPrimary = Color(0xFFE7ECEA);
  static const Color darkTextSecondary = Color(0xFFAFBAB7);
  static const Color darkOutline = Color(0xFF39423F);
  static const Color darkGood = Color(0xFF6ED9A2);
  static const Color darkWarning = Color(0xFFE3BD64);
  static const Color darkBad = Color(0xFFF2A09C);
  static const Color darkBlocked = Color(0xFFB9B4C4);

  /// Status colours are used as text and as chips; on dark they must stay
  /// readable against `darkSurface`, which is why they are lighter here.
  static ColorScheme get light => const ColorScheme.light(
    primary: primary,
    onPrimary: onPrimary,
    secondary: primary,
    onSecondary: onPrimary,
    error: bad,
    onError: onPrimary,
    surface: surface,
    onSurface: textPrimary,
    onSurfaceVariant: textSecondary,
    outline: outline,
    outlineVariant: outline,
  );

  static ColorScheme get dark => const ColorScheme.dark(
    primary: darkPrimary,
    onPrimary: darkOnPrimary,
    secondary: darkPrimary,
    onSecondary: darkOnPrimary,
    error: darkBad,
    onError: darkOnPrimary,
    surface: darkSurface,
    onSurface: darkTextPrimary,
    onSurfaceVariant: darkTextSecondary,
    outline: darkOutline,
    outlineVariant: darkOutline,
  );
}
