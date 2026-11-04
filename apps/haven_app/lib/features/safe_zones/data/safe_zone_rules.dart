/// The bounds `public.safe_zones` enforces, stated once for the editor.
///
/// These are the database's own CHECK constraints, copied from
/// `docs/stage2/migrations/A3-staging-load-v1.sql:484-487`
/// (`safe_zones_name_check` 1..60, `safe_zones_radius_m_check` 50..5000,
/// `safe_zones_lat_check` -90..90, `safe_zones_lng_check` -180..180). Validating
/// them here saves a round-trip and a confusing refusal; it does not replace the
/// constraint, and a write that slips past this still gets refused by the
/// database.
abstract final class SafeZoneRules {
  static const int nameMin = 1;
  static const int nameMax = 60;

  /// The smallest circle the schema allows. Below this a zone flickers on and off
  /// with ordinary GPS error, which is why the number is a constraint and not a
  /// preference.
  static const double radiusMin = 50;
  static const double radiusMax = 5000;

  static String? name(String value) {
    final String trimmed = value.trim();
    if (trimmed.length < nameMin) {
      return 'A place needs a name the child can recognise.';
    }
    if (trimmed.length > nameMax) {
      return 'That name is longer than the $nameMax characters this field '
          'holds.';
    }
    return null;
  }

  static String? radius(String value) {
    final double? parsed = double.tryParse(value.trim());
    if (parsed == null) return 'The radius has to be a number of metres.';
    if (parsed < radiusMin || parsed > radiusMax) {
      return 'The radius has to be between ${radiusMin.toInt()} and '
          '${radiusMax.toInt()} metres.';
    }
    return null;
  }

  static String? lat(String value) => _angle(value, 90, 'latitude');
  static String? lng(String value) => _angle(value, 180, 'longitude');

  static String? _angle(String value, double bound, String which) {
    final double? parsed = double.tryParse(value.trim());
    if (parsed == null) return 'The $which has to be a number.';
    if (parsed < -bound || parsed > bound) {
      return 'That is not a valid $which: it has to be between '
          '-${bound.toInt()} and ${bound.toInt()}.';
    }
    return null;
  }

  /// Every field the editor holds, checked at once, so a save attempt says what
  /// is wrong instead of refusing silently.
  static Map<String, String?> all({
    required String name,
    required String lat,
    required String lng,
    required String radiusM,
  }) => {
    'name': SafeZoneRules.name(name),
    'lat': SafeZoneRules.lat(lat),
    'lng': SafeZoneRules.lng(lng),
    'radius_m': SafeZoneRules.radius(radiusM),
  };

  static bool isClean(Map<String, String?> errors) =>
      errors.values.every((String? error) => error == null);

  /// The coordinates as the row holds them, or null when either one is not a
  /// number. A draft that will not parse is never sent.
  static (double, double)? point(String lat, String lng) {
    final double? north = double.tryParse(lat.trim());
    final double? east = double.tryParse(lng.trim());
    if (north == null || east == null) return null;
    return (north, east);
  }

  static double? metres(String value) => double.tryParse(value.trim());
}
