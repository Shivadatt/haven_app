import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart' show SafeZone;

import '../../../core/errors/captured_gaps.dart';
import '../../family/data/family_scope.dart';
import 'zones_models.dart';
import 'zones_repository.dart';

/// Offline safe places: the INSERT the cloud refused is just a row write here.
///
/// On this phone the row is the record, so creating one goes through the
/// same writer the edits already use. Converts refusal #12 (create safe zone)
/// and refusal #11 (presence calculation) by operating locally.
final class LocalSafeZonesRepository implements SafeZonesRepository {
  LocalSafeZonesRepository({
    required FamilyScopeReader Function() scope,
    required RowReader Function() rows,
    required RowWriter Function() writer,
  }) : _scope = scope,
       _rows = rows,
       _writer = writer,
       _base = HavenSafeZonesRepository(
         scope: scope,
         rows: rows,
         writer: writer,
       );

  final FamilyScopeReader Function() _scope;
  final RowReader Function() _rows;
  final RowWriter Function() _writer;

  final HavenSafeZonesRepository _base;

  factory LocalSafeZonesRepository.live() {
    final FamilyScopeReader reader = FamilyScopeReader(
      auth: () => HavenBackend.auth,
      rows: () => HavenBackend.rows,
    );
    return LocalSafeZonesRepository(
      scope: () => reader,
      rows: () => HavenBackend.rows,
      writer: () => HavenBackend.writer,
    );
  }

  @override
  Future<Result<ZoneBoard?>> load() async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) {
      final HavenFailure why = scope.failureOrNull!;
      return FamilyScopeReader.isMissingFamily(why)
          ? const Ok<ZoneBoard?>(null)
          : Err<ZoneBoard?>(why);
    }

    final Result<List<Map<String, Object?>>> rows = await _rows().rows(
      TableName.safeZones,
      eq: {'family_id': mine.familyId},
      orderDesc: 'created_at',
      limit: 50,
    );
    final HavenFailure? readFailure = rows.failureOrNull;
    if (readFailure != null) return Err<ZoneBoard?>(readFailure);

    return Ok<ZoneBoard?>(
      ZoneBoard(
        familyId: mine.familyId,
        zones: rows.valueOrNull!.map(SafeZone.fromRow).toList(growable: false),
        createGap: HavenSafeZonesRepository.createGap,
        presenceGap: CapturedGaps.presenceGap,
        isOffline: true,
      ),
    );
  }

  @override
  Future<Result<SafeZone>> zone(String zoneId) => _base.zone(zoneId);

  @override
  Future<Result<void>> save({
    required String zoneId,
    required ZoneDraft draft,
  }) async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<void>(scope.failureOrNull!);

    final uniqueCheck = await _checkNameUnique(
      familyId: mine.familyId,
      name: draft.name,
      excludeZoneId: zoneId,
    );
    if (uniqueCheck != null) return Err<void>(uniqueCheck);

    return _base.save(zoneId: zoneId, draft: draft);
  }

  @override
  Future<Result<void>> remove({required String zoneId}) =>
      _base.remove(zoneId: zoneId);

  @override
  Future<Result<void>> create({required ZoneDraft draft}) async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<void>(scope.failureOrNull!);

    final Map<String, Object?>? row = draft.toRow();
    if (row == null) {
      return const Err<void>(
        ValidationFailure(
          'The place needs a name, a position and a radius.',
          field: 'zone',
        ),
      );
    }

    final uniqueCheck = await _checkNameUnique(
      familyId: mine.familyId,
      name: draft.name,
    );
    if (uniqueCheck != null) return Err<void>(uniqueCheck);

    return _writer().insert(
      TableName.safeZones,
      <String, Object?>{
        'id': LocalIds.create(),
        'family_id': mine.familyId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        ...row,
      },
    );
  }

  Future<HavenFailure?> _checkNameUnique({
    required String familyId,
    required String name,
    String? excludeZoneId,
  }) async {
    final Result<List<Map<String, Object?>>> existing = await _rows().rows(
      TableName.safeZones,
      eq: {'family_id': familyId},
    );
    final List<Map<String, Object?>>? rows = existing.valueOrNull;
    if (rows == null) return null;

    final trimmed = name.trim().toLowerCase();
    for (final r in rows) {
      if (excludeZoneId != null && r['id'] == excludeZoneId) continue;
      final existingName = (r['name'] as String?)?.trim().toLowerCase();
      if (existingName == trimmed) {
        return ValidationFailure(
          'A safe place named "${name.trim()}" already exists for your family.',
          field: 'name',
        );
      }
    }
    return null;
  }
}
