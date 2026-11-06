/// Spacing and shape scale for the child app. Nothing in the app hard-codes
/// a padding value. Same scale as the parent so both apps sit on one grid.
abstract final class ChildSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Screen gutter — wider than `md` so text lines never touch the edge.
  static const double gutter = 20;

  /// Smallest tappable area the app will ship.
  static const double touchTarget = 48;
}

abstract final class ChildRadius {
  static const double sm = 8;
  static const double md = 12;

  /// Fully rounded — used only for chips, never for cards.
  static const double pill = 999;
}
