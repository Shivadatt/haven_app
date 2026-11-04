import 'package:haven_api/haven_api.dart';
import 'package:haven_app/core/errors/captured_gaps.dart';
import 'package:haven_app/features/safe_zones/data/zones_models.dart';
import 'package:haven_app/features/safe_zones/data/zones_repository.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// Fixtures shaped like `public.safe_zones` as captured: `name`, `lat`, `lng`,
/// `radius_m` and `active` are the five the write grant names
/// (`docs/stage1/04-rls-matrix.md:33`), and the defaults sit inside the CHECK
/// bounds copied into `safe_zone_rules.dart`
/// (`docs/stage2/migrations/A3-staging-load-v1.sql:484-487`).
Map<String, Object?> zoneRow(
  String id, {
  String familyId = 'f1',
  String name = 'School',
  double lat = 37.7749,
  double lng = -122.4194,
  double radiusM = 150,
  bool active = true,
  String createdAt = '2026-01-05T10:00:00.000Z',
}) => {
  'id': id,
  'family_id': familyId,
  'name': name,
  'lat': lat,
  'lng': lng,
  'radius_m': radiusM,
  'active': active,
  'created_at': createdAt,
};

/// The tables the safe-place read touches. The membership row is the only thing
/// that can give a family id, so it is seeded here rather than assumed.
Map<String, List<Map<String, Object?>>> zonesTables({
  List<Map<String, Object?>> zones = const [],
}) => {
  TableName.familyMembers: const [
    {
      'id': 'm-u1',
      'family_id': 'f1',
      'user_id': 'u1',
      'role': 'parent',
      'status': 'active',
      'created_at': '2026-01-05T10:00:00.000Z',
    },
  ],
  TableName.safeZones: zones,
};

/// A parsed zone for the controller and widget tests.
SafeZone zone(
  String id, {
  String name = 'School',
  double lat = 37.7749,
  double lng = -122.4194,
  double radiusM = 150,
  bool active = true,
}) => SafeZone.fromRow(
  zoneRow(id, name: name, lat: lat, lng: lng, radiusM: radiusM, active: active),
);

ZoneBoard board({List<SafeZone> zones = const [], BlockedFailure? createGap}) =>
    ZoneBoard(
      familyId: 'f1',
      zones: zones,
      createGap: createGap ?? HavenSafeZonesRepository.createGap,
      presenceGap: CapturedGaps.presenceGap,
    );

/// A form holding something a parent could have typed.
ZoneDraft draft({
  String name = 'School',
  String lat = '37.7749',
  String lng = '-122.4194',
  String radiusM = '150',
  bool active = true,
}) =>
    ZoneDraft(name: name, lat: lat, lng: lng, radiusM: radiusM, active: active);

/// The safe-place lane's answers.
///
/// Reads are refused unless a board or a zone is seeded, so a test that forgets
/// to seed fails on its own assertion instead of passing on a fabricated empty
/// list — the same rule the other feature fakes follow. The two write failures
/// are separate from the read failures because the tests that need a readable
/// row and a refused save are the whole point of this lane.
class FakeSafeZonesRepository implements SafeZonesRepository {
  FakeSafeZonesRepository({
    this.board,
    this.found,
    this.noFamily = false,
    this.readFailWith,
    this.writeFailWith,
  });

  ZoneBoard? board;

  /// What `zone(id)` answers. Null means "that id is not in this family".
  SafeZone? found;

  bool noFamily;

  /// Refuses `load` and `zone`.
  HavenFailure? readFailWith;

  /// Refuses `save` and `remove`.
  HavenFailure? writeFailWith;

  int loadCount = 0;
  final List<String> readIds = [];
  final List<ZoneDraft> saved = [];
  final List<String> savedIds = [];
  final List<String> removedIds = [];
  int createCount = 0;

  /// The draft the last successful save wrote, so a test can assert on the
  /// columns rather than on a call count.
  ZoneDraft? get lastSaved => saved.isEmpty ? null : saved.last;

  @override
  Future<Result<ZoneBoard?>> load() async {
    loadCount++;
    final HavenFailure? failure = readFailWith;
    if (failure != null) return Err<ZoneBoard?>(failure);
    if (noFamily) return const Ok<ZoneBoard?>(null);
    final ZoneBoard? read = board;
    return read == null
        ? blocked<ZoneBoard?>('fake: no place read seeded')
        : Ok<ZoneBoard?>(read);
  }

  @override
  Future<Result<SafeZone>> zone(String zoneId) async {
    readIds.add(zoneId);
    final HavenFailure? failure = readFailWith;
    if (failure != null) return Err<SafeZone>(failure);
    if (noFamily) {
      return Err<SafeZone>(
        const ValidationFailure(
          'Set up Haven first — this account is not in a family yet.',
          field: 'family',
        ),
      );
    }
    final SafeZone? hit = found;
    return hit == null
        ? blocked<SafeZone>('fake: no place seeded')
        : Ok<SafeZone>(hit);
  }

  @override
  Future<Result<void>> save({
    required String zoneId,
    required ZoneDraft draft,
  }) async {
    savedIds.add(zoneId);
    saved.add(draft);
    final HavenFailure? failure = writeFailWith;
    return failure == null ? okVoid() : Err<void>(failure);
  }

  @override
  Future<Result<void>> remove({required String zoneId}) async {
    removedIds.add(zoneId);
    final HavenFailure? failure = writeFailWith;
    return failure == null ? okVoid() : Err<void>(failure);
  }

  @override
  Future<Result<void>> create({required ZoneDraft draft}) async {
    createCount++;
    return Err<void>(HavenSafeZonesRepository.createGap);
  }
}
