import 'package:flutter/material.dart';

/// The child app's type scale. Six styles, no more — the same scale as the
/// parent, owned independently.
///
/// Colours are deliberately absent: each style inherits from the surrounding
/// theme or `DefaultTextStyle`, so light and dark stay correct without a
/// second set of names.
abstract final class ChildText {
  static const TextStyle largeTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.2,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0.1,
  );

  /// A `TextTheme` in the same scale, for anything that consumes the theme
  /// rather than these getters (app bar, dialogs, list items).
  static TextTheme textTheme(Color primary, Color secondary) => TextTheme(
    displaySmall: largeTitle.copyWith(color: primary),
    headlineSmall: title.copyWith(color: primary),
    titleLarge: headline.copyWith(color: primary),
    titleMedium: headline.copyWith(color: primary, fontSize: 17),
    bodyLarge: body.copyWith(color: primary),
    bodyMedium: body.copyWith(color: secondary, fontSize: 15),
    bodySmall: caption.copyWith(color: secondary),
    labelLarge: label.copyWith(color: primary),
    labelMedium: label.copyWith(color: secondary, fontSize: 13),
    labelSmall: caption.copyWith(color: secondary, fontSize: 12),
  );
}
