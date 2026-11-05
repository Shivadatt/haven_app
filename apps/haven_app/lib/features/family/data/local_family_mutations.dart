// ignore_for_file: prefer_initializing_formals, use_null_aware_elements

import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'family_models.dart';
import 'family_scope.dart';

/// Database mutation operations for offline family & child management.
final class LocalFamilyMutations {
  const LocalFamilyMutations({
    required FamilyScopeReader Function() scope,
    required RowWriter Function() writer,
  }) : _scope = scope,
       _writer = writer;

  final FamilyScopeReader Function() _scope;
  final RowWriter Function() _writer;

  static String _now() => DateTime.now().toUtc().toIso8601String();

  Future<Result<void>> createFamily({required String name}) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 80) {
      return const Err<void>(
        ValidationFailure(
          'Use between 1 and 80 characters.',
          field: 'family_name',
        ),
      );
    }
    final Result<AuthSession> signedIn = await _scope().session();
    final AuthSession? session = signedIn.valueOrNull;
    if (session == null) return Err<void>(signedIn.failureOrNull!);

    final String familyId = LocalIds.create();
    final Result<void> created = await _writer().insert(
      TableName.families,
      <String, Object?>{
        'id': familyId,
        'name': trimmed,
        'created_at': _now(),
      },
    );
    if (created.isErr) return created;

    final Result<void> joined = await _writer().insert(
      TableName.familyMembers,
      <String, Object?>{
        'id': LocalIds.create(),
        'family_id': familyId,
        'user_id': session.userId,
        'role': 'parent',
        'status': 'active',
        'created_at': _now(),
      },
    );
    if (joined.isErr) {
      await _writer().delete(TableName.families, eq: {'id': familyId});
      return joined;
    }
    return okVoid();
  }

  Future<Result<FamilyPerson>> addChild({
    required String name,
    String? ageBracket,
    String? avatar,
  }) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 60) {
      return const Err<FamilyPerson>(
        ValidationFailure('Use between 1 and 60 characters.', field: 'name'),
      );
    }
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<FamilyPerson>(scope.failureOrNull!);

    final String childUserId = LocalIds.create();
    final String now = _now();
    final Result<void> profileResult = await _writer().insert(
      TableName.profiles,
      <String, Object?>{
        'id': childUserId,
        'role': 'child',
        'display_name': trimmed,
        if (ageBracket != null) 'age_bracket': ageBracket,
        if (avatar != null) 'avatar': avatar,
        'created_at': now,
        'updated_at': now,
      },
    );
    if (profileResult.isErr) {
      return Err<FamilyPerson>(profileResult.failureOrNull!);
    }

    final String memberId = LocalIds.create();
    final Result<void> memberResult = await _writer().insert(
      TableName.familyMembers,
      <String, Object?>{
        'id': memberId,
        'family_id': mine.familyId,
        'user_id': childUserId,
        'role': 'child',
        'status': 'active',
        'created_at': now,
      },
    );
    if (memberResult.isErr) {
      await _writer().delete(TableName.profiles, eq: {'id': childUserId});
      return Err<FamilyPerson>(memberResult.failureOrNull!);
    }

    return Ok<FamilyPerson>(
      FamilyPerson(
        member: FamilyMember(
          id: memberId,
          familyId: mine.familyId,
          userId: childUserId,
          role: 'child',
          status: 'active',
          createdAt: DateTime.tryParse(now),
        ),
        profile: Profile(
          id: childUserId,
          role: 'child',
          displayName: trimmed,
          ageBracket: ageBracket,
          avatar: avatar,
          createdAt: DateTime.tryParse(now),
          updatedAt: DateTime.tryParse(now),
        ),
      ),
    );
  }

  Future<Result<void>> updateChild({
    required String childUserId,
    required String name,
    String? ageBracket,
    String? avatar,
  }) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 60) {
      return const Err<void>(
        ValidationFailure('Use between 1 and 60 characters.', field: 'name'),
      );
    }
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<void>(scope.failureOrNull!);

    return _writer().update(
      TableName.profiles,
      <String, Object?>{
        'display_name': trimmed,
        if (ageBracket != null) 'age_bracket': ageBracket,
        if (avatar != null) 'avatar': avatar,
        'updated_at': _now(),
      },
      eq: {'id': childUserId},
    );
  }

  Future<Result<void>> unlinkChild(
    String childUserId, {
    bool execute = false,
  }) async {
    if (!execute) return okVoid();
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<void>(scope.failureOrNull!);

    final String now = _now();
    final Result<void> updated = await _writer().update(
      TableName.familyMembers,
      <String, Object?>{'status': 'removed', 'removed_at': now},
      eq: {'family_id': mine.familyId, 'user_id': childUserId},
    );
    if (updated.isErr) return updated;

    await _writer().update(
      TableName.devices,
      <String, Object?>{
        'status': 'revoked',
        'credential_revoked_at': now,
        'updated_at': now,
      },
      eq: {'family_id': mine.familyId, 'child_user_id': childUserId},
    );
    return okVoid();
  }
}
