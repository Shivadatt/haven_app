import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'safe_zone_rules.dart';

/// The editor's working copy of a zone.
///
/// Everything is text because the fields are typed into a form: a `double` field
/// cannot hold "37." while the parent is still writing it, and refusing the
/// keystroke would read as the app fighting back.
final class ZoneDraft {
  const ZoneDraft({
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusM,
    required this.active,
  });

  /// The row a parent opened the editor on.
  factory ZoneDraft.of(SafeZone zone) => ZoneDraft(
    name: zone.name,
    lat: zone.lat.toString(),
    lng: zone.lng.toString(),
    radiusM: zone.radiusM.toString(),
    active: zone.active,
  );

  final String name;
  final String lat;
  final String lng;
  final String radiusM;
  final bool active;

  Map<String, String?> get errors =>
      SafeZoneRules.all(name: name, lat: lat, lng: lng, radiusM: radiusM);

  bool get isValid => SafeZoneRules.isClean(errors);

  /// The columns the captured grant actually lets this app write
  /// (`docs/stage1/04-rls-matrix.md:33`): `name`, `lat`, `lng`, `radius_m`,
  /// `active`. Nothing else is ever sent, so a refused write cannot be blamed on
  /// a column the parent never touched.
  ///
  /// Null when the numbers will not parse — a draft that is not a point is not
  /// sent.
  Map<String, Object?>? toRow() {
    final (double lat, double lng)? point = SafeZoneRules.point(lat, lng);
    final double? radius = SafeZoneRules.metres(radiusM);
    if (point == null || radius == null) return null;
    return {
      'name': name.trim(),
      'lat': point.$1,
      'lng': point.$2,
      'radius_m': radius,
      'active': active,
    };
  }

  ZoneDraft copyWith({
    String? name,
    String? lat,
    String? lng,
    String? radiusM,
    bool? active,
  }) => ZoneDraft(
    name: name ?? this.name,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    radiusM: radiusM ?? this.radiusM,
    active: active ?? this.active,
  );
}

/// The places this family owns, and the two things it cannot do with them.
final class ZoneBoard {
  const ZoneBoard({
    required this.familyId,
    required this.zones,
    required this.createGap,
    required this.presenceGap,
  });

  final String familyId;
  final List<SafeZone> zones;

  /// Adding a place. `safe_zones` has an INSERT policy but no INSERT grant for
  /// `authenticated`, so no client can insert (`docs/stage1/04-rls-matrix.md:33`,
  /// `:147` — F6).
  final BlockedFailure createGap;

  /// Whether a device is inside one of these circles. `safe_zone_states` is
  /// deny-all for `authenticated` (see `presenceLaneMissing` in
  /// `core/errors/captured_gaps.dart`), so a zone list can be read but the answer
  /// is not.
  final BlockedFailure presenceGap;

  bool get hasZones => zones.isNotEmpty;

  /// Zones are read, not counted as a statistic: a parent deciding whether to add
  /// one needs to know how many are *named*, and `safe_zones` rows are few.
  String get counted =>
      '${zones.length} ${zones.length == 1 ? 'place' : 'places'} named for '
      'this family.';

  int get activeCount => zones.where((SafeZone zone) => zone.active).length;
}
