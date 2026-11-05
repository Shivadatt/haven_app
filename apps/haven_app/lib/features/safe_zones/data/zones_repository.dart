import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../core/errors/captured_gaps.dart';
import '../../family/data/family_scope.dart';
import 'zones_models.dart';

/// The places the family named, and the writes the captured grants allow on them.
abstract interface class SafeZonesRepository {
  /// Null means this account has no family yet, which the screen routes to setup.
  Future<Result<ZoneBoard?>> load();

  /// One zone by id, scoped to the caller's own family.
  Future<Result<SafeZone>> zone(String zoneId);

  /// Writes the five columns `authenticated` holds UPDATE on. Parent-only under
  /// RLS, so a child account is refused by the database and that refusal is
  /// reported.
  Future<Result<void>> save({required String zoneId, required ZoneDraft draft});

  /// Removes the zone. `safe_zones` is the one table in the captured grant set
  /// that lets a signed-in client delete at all (`04-rls-matrix.md:33`, `:149`).
  Future<Result<void>> remove({required String zoneId});

  /// Always refused: the policy exists, the grant does not.
  Future<Result<void>> create({required ZoneDraft draft});
}

final class HavenSafeZonesRepository implements SafeZonesRepository {
  HavenSafeZonesRepository({
    required FamilyScopeReader Function() scope,
    required RowReader Function() rows,
    required RowWriter Function() writer,
  }) : _scope = scope,
       _rows = rows,
       _writer = writer;

  /// Providers, not values: `HavenBackend.install()` is asynchronous.
  final FamilyScopeReader Function() _scope;
  final RowReader Function() _rows;
  final RowWriter Function() _writer;

  /// The INSERT verdict, stated once for both screens that could offer it.
  static const String createMissing =
      '`safe_zones` carries `safe_zones_insert_parent` but `authenticated` has '
      'no INSERT grant on the table, so the policy is unreachable from any '
      'client (04-rls-matrix.md:33, :147 — F6); no Edge Function that creates '
      'zones is deployed';

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
        createGap: createGap,
        presenceGap: CapturedGaps.presenceGap,
      ),
    );
  }

  @override
  Future<Result<SafeZone>> zone(String zoneId) async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<SafeZone>(scope.failureOrNull!);
    if (zoneId.isEmpty) {
      return const Err<SafeZone>(
        ValidationFailure('No place was named to edit.', field: 'zone'),
      );
    }

    final Result<Map<String, Object?>?> row = await _rows().first(
      TableName.safeZones,
      eq: {'id': zoneId, 'family_id': mine.familyId},
    );
    final HavenFailure? readFailure = row.failureOrNull;
    if (readFailure != null) return Err<SafeZone>(readFailure);

    final Map<String, Object?>? found = row.valueOrNull;
    if (found == null) {
      return const Err<SafeZone>(
        ValidationFailure(
          "That place is not in your family, so there is nothing to edit.",
          field: 'zone',
        ),
      );
    }
    return Ok<SafeZone>(SafeZone.fromRow(found));
  }

  @override
  Future<Result<void>> save({
    required String zoneId,
    required ZoneDraft draft,
  }) async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<void>(scope.failureOrNull!);

    final Map<String, Object?>? row = draft.toRow();
    if (row == null) {
      return Err<void>(
        ValidationFailure(
          draft.errors.values.firstWhere(
                (String? error) => error != null,
                orElse: () => null,
              ) ??
              'The place needs a name, a position and a radius.',
          field: 'zone',
        ),
      );
    }

    // The family id comes from the caller's own membership row, never from the
    // form: a matching filter is what stops an edit from landing on another
    // family's zone.
    return _writer().update(
      TableName.safeZones,
      row,
      eq: {'id': zoneId, 'family_id': mine.familyId},
    );
  }

  @override
  Future<Result<void>> remove({required String zoneId}) async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<void>(scope.failureOrNull!);

    return _writer().delete(
      TableName.safeZones,
      eq: {'id': zoneId, 'family_id': mine.familyId},
    );
  }

  @override
  Future<Result<void>> create({required ZoneDraft draft}) async =>
      Err<void>(createGap);

  /// The same refusal, as a value the board carries so the list page can show it
  /// without a widget having to guess the words.
  static BlockedFailure get createGap => BlockedFailure(
    'Haven cannot name a new place in this build yet.',
    missing: createMissing,
    detail: 'BLOCKED — SPECIFICATION REQUIRED: $createMissing',
  );
}
