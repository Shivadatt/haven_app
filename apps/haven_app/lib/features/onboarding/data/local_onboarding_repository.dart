import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import 'onboarding_repository.dart';

/// Offline first-run setup: creates family and child rows directly in local tables.
final class LocalOnboardingRepository implements OnboardingRepository {
  LocalOnboardingRepository({
    required UserAuth Function() auth,
    required RowReader Function() rows,
    required RowWriter Function() writer,
    required ProfileStore Function() profiles,
  }) : _auth = auth,
       _rows = rows,
       _writer = writer,
       _profiles = profiles;

  final UserAuth Function() _auth;
  final RowReader Function() _rows;
  final RowWriter Function() _writer;
  final ProfileStore Function() _profiles;

  factory LocalOnboardingRepository.live() => LocalOnboardingRepository(
    auth: () => HavenBackend.auth,
    rows: () => HavenBackend.rows,
    writer: () => HavenBackend.writer,
    profiles: () => HavenBackend.profiles,
  );

  static String _now() => DateTime.now().toUtc().toIso8601String();

  @override
  Future<Result<void>> claimParentRole() async {
    final Result<AuthSession> signedIn = await _session();
    final AuthSession? mine = signedIn.valueOrNull;
    if (mine == null) return Err<void>(signedIn.failureOrNull!);
    return _writer().update(
      TableName.profiles,
      <String, Object?>{
        'role': 'parent',
        'updated_at': _now(),
      },
      eq: {'id': mine.userId},
    );
  }

  @override
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
    final Result<AuthSession> signedIn = await _session();
    final AuthSession? mine = signedIn.valueOrNull;
    if (mine == null) return Err<void>(signedIn.failureOrNull!);

    final Result<Map<String, Object?>?> already = await _rows().first(
      TableName.familyMembers,
      eq: {'user_id': mine.userId},
    );
    final HavenFailure? readFailure = already.failureOrNull;
    if (readFailure != null) return Err<void>(readFailure);
    if (already.valueOrNull != null) return okVoid();

    final String familyId = LocalIds.create();
    final Result<void> created = await _writer().insert(
      TableName.families,
      <String, Object?>{
        'id': familyId,
        'name': trimmed,
        'created_at': _now(),
      },
    );
    final HavenFailure? createFailure = created.failureOrNull;
    if (createFailure != null) return Err<void>(createFailure);

    final Result<void> joined = await _writer().insert(
      TableName.familyMembers,
      <String, Object?>{
        'id': LocalIds.create(),
        'family_id': familyId,
        'user_id': mine.userId,
        'role': 'parent',
        'status': 'active',
        'created_at': _now(),
      },
    );
    if (joined.failureOrNull != null) {
      await _writer().delete(TableName.families, eq: {'id': familyId});
      return Err<void>(joined.failureOrNull!);
    }
    return okVoid();
  }

  @override
  Future<Result<String>> createChild({
    required String name,
    required String ageGroup,
    String? avatar,
  }) async {
    final String trimmed = name.trim();
    final String? invalid = validateDisplayName(trimmed);
    if (invalid != null) {
      return Err<String>(ValidationFailure(invalid, field: 'child_name'));
    }
    final Result<AuthSession> signedIn = await _session();
    final AuthSession? mine = signedIn.valueOrNull;
    if (mine == null) return Err<String>(signedIn.failureOrNull!);

    final Result<Map<String, Object?>?> memberRow = await _rows().first(
      TableName.familyMembers,
      eq: {'user_id': mine.userId},
    );
    final HavenFailure? readFailure = memberRow.failureOrNull;
    if (readFailure != null) return Err<String>(readFailure);
    final String? familyId = memberRow.valueOrNull?['family_id'] as String?;
    if (familyId == null) {
      return const Err<String>(
        BackendFailure('No family found. Please create a family first.'),
      );
    }

    final String childId = LocalIds.create();
    final String now = _now();
    final Result<void> profileResult = await _writer().insert(
      TableName.profiles,
      <String, Object?>{
        'id': childId,
        'role': 'child',
        'display_name': trimmed,
        'age_group': ageGroup,
        'avatar': avatar ?? 'bear',
        'created_at': now,
        'updated_at': now,
      },
    );
    if (profileResult.failureOrNull != null) {
      return Err<String>(profileResult.failureOrNull!);
    }

    final Result<void> memberResult = await _writer().insert(
      TableName.familyMembers,
      <String, Object?>{
        'id': LocalIds.create(),
        'family_id': familyId,
        'user_id': childId,
        'role': 'child',
        'status': 'active',
        'created_at': now,
      },
    );
    if (memberResult.failureOrNull != null) {
      await _writer().delete(TableName.profiles, eq: {'id': childId});
      return Err<String>(memberResult.failureOrNull!);
    }
    return Ok<String>(childId);
  }

  @override
  Future<Result<bool>> hasProfile(String userId) async {
    final Result<Map<String, Object?>?> row = await _profiles().load(userId);
    final HavenFailure? failure = row.failureOrNull;
    if (failure != null) return Err<bool>(failure);
    return Ok<bool>(row.valueOrNull != null);
  }

  Future<Result<AuthSession>> _session() async {
    final Result<AuthSession?> raw = await _auth().currentSession();
    final HavenFailure? failure = raw.failureOrNull;
    if (failure != null) return Err<AuthSession>(failure);
    final AuthSession? session = raw.valueOrNull;
    return session == null
        ? const Err<AuthSession>(
            AuthFailure('You are not signed in.', signedOut: true),
          )
        : Ok<AuthSession>(session);
  }
}
