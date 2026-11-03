import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart' show Profile, ProfileRole;

/// The signed-in parent, as this screen can actually see them.
final class AccountInfo {
  const AccountInfo({required this.userId, this.email, this.profile});

  final String userId;

  /// From the Supabase session. Displayed; never sent anywhere by this screen.
  final String? email;

  /// Null when the `profiles` row does not exist yet. Provisioning has no
  /// approved implementation
  /// (`docs/stage2/S2-EXEC-08-identity-decision-A13-final.md` §2(4)), so this is
  /// an expected state rather than a fault.
  final Profile? profile;

  bool get hasProfile => profile != null;
  ProfileRole? get role => profile?.profileRole;
}

/// What the account screen may read and change about its own user.
///
/// The last three are the documented abilities with no approved contract. They
/// stay typed and answer `blocked(...)` — the screen reads the refusal back
/// instead of offering a button that cannot work.
abstract interface class AccountRepository {
  Future<Result<AccountInfo>> load();
  Future<Result<void>> rename({required String displayName});
  Future<Result<void>> signOut();
  Future<Result<void>> passwordChange();
  Future<Result<void>> emailChange();
  Future<Result<void>> accountDeletion();
}

final class HavenAccountRepository implements AccountRepository {
  HavenAccountRepository({required this._auth, required this._profiles});

  /// Providers, not values: `HavenBackend.install()` is async.
  final UserAuth Function() _auth;
  final ProfileStore Function() _profiles;

  factory HavenAccountRepository.live() => HavenAccountRepository(
    auth: () => HavenBackend.auth,
    profiles: () => HavenBackend.profiles,
  );

  @override
  Future<Result<AccountInfo>> load() async {
    final Result<AuthSession> signedIn = await _session();
    final AuthSession? session = signedIn.valueOrNull;
    if (session == null) return Err<AccountInfo>(signedIn.failureOrNull!);

    final Result<Map<String, Object?>?> row = await _profiles().load(
      session.userId,
    );
    final HavenFailure? readFailure = row.failureOrNull;
    if (readFailure != null) return Err<AccountInfo>(readFailure);

    final Map<String, Object?>? data = row.valueOrNull;
    return Ok<AccountInfo>(
      AccountInfo(
        userId: session.userId,
        email: session.email,
        profile: data == null ? null : Profile.fromRow(data),
      ),
    );
  }

  @override
  Future<Result<void>> rename({required String displayName}) async {
    final String trimmed = displayName.trim();
    final String? invalid = validateDisplayName(trimmed);
    if (invalid != null) {
      return Err<void>(ValidationFailure(invalid, field: 'display_name'));
    }
    final Result<AuthSession> signedIn = await _session();
    final String? userId = signedIn.valueOrNull?.userId;
    if (userId == null) return Err<void>(signedIn.failureOrNull!);
    return _profiles().updateDisplayName(userId, trimmed);
  }

  @override
  Future<Result<void>> signOut() => _auth().signOut();

  @override
  Future<Result<void>> passwordChange() async => blocked(
    'UserAuth has no password-change method and none of the nine captured '
    'Edge Functions offers one (docs/stage1/evidence/edge-functions/)',
    requirement: 'Haven cannot change your password yet.',
  );

  @override
  Future<Result<void>> emailChange() async => blocked(
    'no approved contract rewrites the email on an existing session; the '
    'captured auth surface only signs in, registers and signs out',
    requirement: 'Haven cannot change your email address yet.',
  );

  @override
  Future<Result<void>> accountDeletion() async => blocked(
    'no approved contract deletes an auth user, and deleting a person would '
    'orphan families, devices and alerts — the cascade is unspecified',
    requirement: 'Haven cannot delete your account from this app yet.',
  );

  /// The session, or the failure that says why there isn't one.
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
