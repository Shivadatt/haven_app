import 'package:haven_core/haven_core.dart';

import 'auth_contracts.dart';
import 'data_contracts.dart';

/// Backend clients for a build that has no staging access.
///
/// This is the normal state of this repository: the schema load (`A2′(a)`, `A3`)
/// and the Firebase approvals (`A12-R`, `A13`) are unsigned, so no developer
/// machine can reach data. These classes let the whole app run and show an honest
/// "not connected" state — they are not test doubles and are never used when the
/// endpoints are configured.
class UnconfiguredBackend
    implements RowReader, RowWriter, RpcCaller, EdgeCaller, SnapshotSource {
  const UnconfiguredBackend(this.reason);

  final String reason;

  Err<T> _refusal<T>() => Err<T>(
    NetworkFailure('This build is not connected to a backend.', detail: reason),
  );

  @override
  Future<Result<List<Map<String, Object?>>>> rows(
    String table, {
    Map<String, Object?> eq = const {},
    String? orderDesc,
    int? limit,
  }) async => _refusal();

  @override
  Future<Result<Map<String, Object?>?>> first(
    String table, {
    Map<String, Object?> eq = const {},
    String? orderDesc,
  }) async => _refusal();

  @override
  Future<Result<int>> count(
    String table, {
    Map<String, Object?> eq = const {},
  }) async => _refusal();

  @override
  Future<Result<void>> insert(String table, Map<String, Object?> row) async =>
      _refusal();

  @override
  Future<Result<void>> update(
    String table,
    Map<String, Object?> row, {
    required Map<String, Object?> eq,
  }) async => _refusal();

  @override
  Future<Result<void>> delete(
    String table, {
    required Map<String, Object?> eq,
  }) async => _refusal();

  @override
  Future<Result<Object?>> call(
    String name,
    Map<String, Object?> params,
  ) async => _refusal();

  @override
  Future<Result<EdgeReply>> invoke(
    String slug,
    Map<String, Object?> body, {
    Map<String, String> deviceHeaders = const {},
  }) async => _refusal();

  @override
  Future<Result<List<Map<String, Object?>>>> familySnapshot(
    String familyId,
  ) async => _refusal();

  @override
  Future<Result<List<Map<String, Object?>>>> deviceSnapshot(
    String deviceId,
  ) async => _refusal();
}

final class UnconfiguredChangeFeed implements ChangeFeed {
  const UnconfiguredChangeFeed();

  @override
  Stream<Map<String, Object?>> changes({
    required String table,
    Map<String, Object?> eq = const {},
  }) => const Stream<Map<String, Object?>>.empty();

  @override
  void dispose() {}
}

final class UnconfiguredUserAuth implements UserAuth {
  const UnconfiguredUserAuth(this.reason);

  final String reason;

  Err<T> _refusal<T>() => Err<T>(
    NetworkFailure('Sign-in is not available in this build.', detail: reason),
  );

  @override
  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  }) async => _refusal();

  @override
  Future<Result<AuthSession>> register({
    required String email,
    required String password,
    required String displayName,
  }) async => _refusal();

  @override
  Future<Result<AuthSession>> signInWithFirebaseToken(
    String firebaseIdToken,
  ) async => blocked(reason);

  @override
  Future<Result<AuthSession?>> currentSession() async => _refusal();

  @override
  Future<Result<AuthSession>> refresh() async => _refusal();

  @override
  Future<Result<void>> signOut() async => okVoid();

  @override
  Stream<AuthStateSnapshot> get states => Stream<AuthStateSnapshot>.value(
    const AuthStateSnapshot(AuthStatusKind.signedOut),
  );
}

final class UnconfiguredProfileStore implements ProfileStore {
  const UnconfiguredProfileStore(this.reason);

  final String reason;

  @override
  Future<Result<Map<String, Object?>?>> load(String userId) async => Err(
    NetworkFailure('This build is not connected to a backend.', detail: reason),
  );

  @override
  Future<Result<void>> updateDisplayName(
    String userId,
    String displayName,
  ) async => Err(
    NetworkFailure('This build is not connected to a backend.', detail: reason),
  );
}

final class UnconfiguredPushTransport implements PushTransport {
  const UnconfiguredPushTransport(this.reason);

  final String reason;

  @override
  Future<Result<String?>> registrationTarget() async => blocked(reason);

  @override
  Future<Result<void>> clearRegistration() async => blocked(reason);

  @override
  Stream<String> get registrationChanges => const Stream<String>.empty();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> get granted async => false;

  @override
  Stream<Map<String, Object?>> get taps =>
      const Stream<Map<String, Object?>>.empty();

  @override
  Stream<Map<String, Object?>> get foregroundMessages =>
      const Stream<Map<String, Object?>>.empty();
}
