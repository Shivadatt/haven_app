import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'family_models.dart';
import 'family_scope.dart';

/// The family screen's whole surface.
///
/// `load`, `rename` and `unlinkChild` are the three things the captured
/// contracts let a signed-in parent do: `families` and `family_members` are
/// readable by a member, `authenticated` holds column UPDATE on
/// `families(name, settings)` for the owner, and `unlink_child` is one of the 14
/// captured RPCs (`docs/stage1/04-rls-matrix.md` §0a). Adding or removing an
/// adult has neither a grant nor a captured function body, so it stays typed and
/// answers `blocked(...)`.
abstract interface class FamilyRepository {
  /// A null payload is not a failure: it means this account has no family yet,
  /// which is the state first-run setup exists to fix.
  Future<Result<FamilyBundle?>> load();

  Future<Result<void>> rename({required String name});

  Future<Result<void>> unlinkChild(String childUserId);

  Future<Result<void>> inviteParent();

  Future<Result<void>> removeParent();
}

final class HavenFamilyRepository implements FamilyRepository {
  HavenFamilyRepository({
    required this._scope,
    required this._rows,
    required this._writer,
    required this._rpc,
  });

  /// Providers, not values: `HavenBackend.install()` is asynchronous.
  final FamilyScopeReader Function() _scope;
  final RowReader Function() _rows;
  final RowWriter Function() _writer;
  final RpcCaller Function() _rpc;

  factory HavenFamilyRepository.live() {
    final FamilyScopeReader reader = FamilyScopeReader(
      auth: () => HavenBackend.auth,
      rows: () => HavenBackend.rows,
    );
    return HavenFamilyRepository(
      scope: () => reader,
      rows: () => HavenBackend.rows,
      writer: () => HavenBackend.writer,
      rpc: () => HavenBackend.rpc,
    );
  }

  @override
  Future<Result<FamilyBundle?>> load() async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) {
      final HavenFailure why = scope.failureOrNull!;
      // "no family yet" is a state the parent can act on, not a read failure.
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
    // `families_name_check` is char_length 1..80
    // (docs/stage2/migrations/A3-staging-load-v1.sql:467).
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
  Future<Result<void>> unlinkChild(String childUserId) async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<void>(scope.failureOrNull!);

    // NOT VERIFIED — RETURN SHAPE UNCAPPED: `g1-q7` captured no return type for
    // `unlink_child`, so the absence of a mapped failure is the only
    // confirmation this client can honestly get.
    final Result<Object?> called = await _rpc().call(
      RpcName.unlinkChild,
      UnlinkChildArgs(
        familyId: mine.familyId,
        childUserId: childUserId,
        actorUserId: mine.session.userId,
      ).toParams(),
    );
    final HavenFailure? failure = called.failureOrNull;
    return failure == null ? okVoid() : Err<void>(failure);
  }

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
