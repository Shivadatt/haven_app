import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// What the identity screens need, in domain terms.
///
/// Exists so a controller never touches `UserAuth` directly: the profile lookup
/// that belongs to the same sign-in gesture lives here, and the row is decoded
/// into [Profile] instead of being handed around as a map.
abstract interface class AuthRepository {
  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  });
  Future<Result<AuthSession>> register({
    required String email,
    required String password,
    required String displayName,
  });
  Future<Result<void>> signOut();
  Future<Result<AuthSession?>> currentSession();

  /// `Ok(null)` is a signed-in account whose profile row does not exist yet —
  /// the documented provisioning gap, not a failure.
  Future<Result<Profile?>> profileFor(String userId);

  Stream<AuthStateSnapshot> get states;

  /// The Firebase-identity bridge. Blocked until the mapping table is approved
  /// and loaded; never a client assertion of a UID.
  Future<Result<AuthSession>> signInWithFirebaseToken(String firebaseIdToken);
}

final class HavenAuthRepository implements AuthRepository {
  HavenAuthRepository({
    required UserAuth Function() auth,
    required ProfileStore Function() profiles,
  }) : _auth = auth,
       _profiles = profiles;

  /// Providers, not values: `HavenBackend.install()` is async, so a client
  /// captured at construction could be the pre-install unconfigured one.
  final UserAuth Function() _auth;
  final ProfileStore Function() _profiles;

  factory HavenAuthRepository.live() => HavenAuthRepository(
    auth: () => HavenBackend.auth,
    profiles: () => HavenBackend.profiles,
  );

  @override
  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  }) => _auth().signInWithPassword(email: email.trim(), password: password);

  @override
  Future<Result<AuthSession>> register({
    required String email,
    required String password,
    required String displayName,
  }) => _auth().register(
    email: email.trim(),
    password: password,
    displayName: displayName.trim(),
  );

  @override
  Future<Result<AuthSession>> signInWithFirebaseToken(String firebaseIdToken) =>
      _auth().signInWithFirebaseToken(firebaseIdToken);

  @override
  Future<Result<AuthSession?>> currentSession() => _auth().currentSession();

  @override
  Future<Result<void>> signOut() => _auth().signOut();

  @override
  Stream<AuthStateSnapshot> get states => _auth().states;

  @override
  Future<Result<Profile?>> profileFor(String userId) async {
    final Result<Map<String, Object?>?> row = await _profiles().load(userId);
    final HavenFailure? failure = row.failureOrNull;
    if (failure != null) return Err<Profile?>(failure);
    final Map<String, Object?>? data = row.valueOrNull;
    return Ok<Profile?>(data == null ? null : Profile.fromRow(data));
  }
}
