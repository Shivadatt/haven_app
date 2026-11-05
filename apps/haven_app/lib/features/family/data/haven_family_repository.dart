import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../core/errors/captured_gaps.dart';
import 'family_models.dart';
import 'family_repository.dart';
import 'family_scope.dart';

final class HavenFamilyRepository implements FamilyRepository {
  HavenFamilyRepository({
    required FamilyScopeReader Function() scope,
    required RowReader Function() rows,
    required RowWriter Function() writer,
  }) : _scope = scope,
       _rows = rows,
       _writer = writer;

  final FamilyScopeReader Function() _scope;
  final RowReader Function() _rows;
  final RowWriter Function() _writer;

  factory HavenFamilyRepository.live() {
    final FamilyScopeReader reader = FamilyScopeReader(
      auth: () => HavenBackend.auth,
      rows: () => HavenBackend.rows,
    );
    return HavenFamilyRepository(
      scope: () => reader,
      rows: () => HavenBackend.rows,
      writer: () => HavenBackend.writer,
    );
  }

  @override
  Future<Result<FamilyBundle?>> load() async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) {
      final HavenFailure why = scope.failureOrNull!;
      if (FamilyScopeReader.isMissingFamily(why)) {
        return const Ok<FamilyBundle?>(null);
      }
      return Err<FamilyBundle?>(why);
    }

    final Result<Map<String, Object?>?> familyRow = await _rows().first(
      TableName.families,
      eq: {'id': mine.familyId},
    );
    final HavenFailure? familyFailure = familyRow.failureOrNull;
    if (familyFailure != null) return Err<FamilyBundle?>(familyFailure);
    final Map<String, Object?>? familyData = familyRow.valueOrNull;
    if (familyData == null) {
      return Err<FamilyBundle?>(
        const BackendFailure(
          'Your family could not be read, so nothing in it can be shown yet.',
        ),
      );
    }

    final Result<List<Map<String, Object?>>> memberRows = await _rows().rows(
      TableName.familyMembers,
      eq: {'family_id': mine.familyId},
    );
    final List<Map<String, Object?>>? members = memberRows.valueOrNull;
    if (members == null) return Err<FamilyBundle?>(memberRows.failureOrNull!);

    final List<FamilyPerson> parents = [];
    final List<FamilyPerson> children = [];
    for (final Map<String, Object?> raw in members) {
      final FamilyMember member = FamilyMember.fromRow(raw);
      if (!member.isActive) continue;
      final Result<Profile?> person = await _profileOf(member.userId);
      final HavenFailure? profileFailure = person.failureOrNull;
      if (profileFailure != null) return Err<FamilyBundle?>(profileFailure);
      (member.familyRole == FamilyRole.child ? children : parents).add(
        FamilyPerson(member: member, profile: person.valueOrNull),
      );
    }

    return Ok<FamilyBundle?>(
      FamilyBundle(
        family: Family.fromRow(familyData),
        parents: parents,
        children: children,
      ),
    );
  }

  @override
  Future<Result<void>> rename({required String name}) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 80) {
      return Err<void>(
        const ValidationFailure(
          'Use between 1 and 80 characters.',
          field: 'family_name',
        ),
      );
    }
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<void>(scope.failureOrNull!);
    return _writer().update(
      TableName.families,
      {'name': trimmed},
      eq: {'id': mine.familyId},
    );
  }

  @override
  Future<Result<void>> unlinkChild(String childUserId, {bool execute = false}) async => blocked(
    '${CapturedGaps.rpcLaneMissing}; the `pairing` Edge Function does have an '
    '`unlink` action (capture-20261030.json:40) but only the `action` field of '
    'its request body was ever captured, and staging has no Edge Functions '
    'deployed',
    requirement:
        'Haven cannot remove a child from your family in this build yet.',
  );

  @override
  Future<Result<void>> inviteParent() async => blocked(
    "`authenticated` has no INSERT grant on `family_members` "
    '(docs/stage1/04-rls-matrix.md §0a) and the `family-admin` Edge '
    "Function's request body was never captured, so there is no contract to call",
    requirement: 'Haven cannot add another parent yet.',
  );

  @override
  Future<Result<void>> removeParent() async => blocked(
    '`authenticated` has no DELETE grant on `family_members`, and no captured '
    'RPC removes an adult from a family (`unlink_child` is child-only)',
    requirement: 'Haven cannot remove another parent yet.',
  );

  @override
  Future<Result<void>> createFamily({required String name}) async =>
      CapturedGaps.rpcUnavailable('create a family');

  @override
  Future<Result<FamilyPerson>> addChild({
    required String name,
    String? ageBracket,
    String? avatar,
  }) async => blocked(
    CapturedGaps.deviceLaneMissing,
    requirement: 'Haven cannot add a child without pairing yet.',
  );

  @override
  Future<Result<void>> updateChild({
    required String childUserId,
    required String name,
    String? ageBracket,
    String? avatar,
  }) async => blocked(
    '`authenticated` has no UPDATE grant on child profiles',
    requirement: 'Haven cannot edit child profiles yet.',
  );

  Future<Result<Profile?>> _profileOf(String userId) async {
    final Result<Map<String, Object?>?> row = await _rows().first(
      TableName.profiles,
      eq: {'id': userId},
    );
    final HavenFailure? failure = row.failureOrNull;
    if (failure != null) return Err<Profile?>(failure);
    final Map<String, Object?>? data = row.valueOrNull;
    return Ok<Profile?>(data == null ? null : Profile.fromRow(data));
  }
}
