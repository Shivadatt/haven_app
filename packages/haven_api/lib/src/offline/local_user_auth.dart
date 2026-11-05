import 'dart:async';

import 'package:haven_core/haven_core.dart';

import '../auth_contracts.dart';
import 'local_ids.dart';
import 'local_tables.dart';

/// Local parent account over the offline tables and the platform vault.
///
/// This is a local session gate, not server authentication: it says "this device
/// remembers one parent", and nothing more. It never claims a password was
/// checked by anyone, and `AuthSession.accessToken` is a local marker, not a
/// bearer token. The secret lives in the [SecretVault] (the app's keystore
/// implementation), never in the JSON document, because the document may be
/// backed up and the vault is not — the same fail-closed posture as `SecureVault`.
///
/// Sign-out clears the session only. Rows and the stored secret survive, so the
/// family database is never lost by leaving the screen.
final class LocalUserAuth implements UserAuth {
  LocalUserAuth(this._tables, this._vault);

  final LocalTables _tables;
  final SecretVault _vault;
  AuthSession? _session;
  final StreamController<AuthStateSnapshot> _states =
      StreamController<AuthStateSnapshot>.broadcast();

  static const String _profilesTable = 'profiles';
  static String _secretKey(String email) => 'local_auth.$email';

  /// Email is the local login key; case is folded so 'Ada@x' and 'ada@x' are one
  /// account, which the duplicate check below relies on.
  static String normalizeEmail(String email) => email.trim().toLowerCase();

  @override
  Future<Result<AuthSession>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final login = normalizeEmail(email);
    if (login.isEmpty || !login.contains('@')) {
      return const Err<AuthSession>(
        ValidationFailure(
          'Enter an email address for this local account.',
          field: 'email',
        ),
      );
    }
    if (password.length < 6) {
      return const Err<AuthSession>(
        ValidationFailure(
          'Choose a local password of at least six characters.',
          field: 'password',
        ),
      );
    }
    if (displayName.trim().isEmpty) {
      return const Err<AuthSession>(
        ValidationFailure('Enter the parent name.', field: 'displayName'),
      );
    }
    if (!_vault.available) {
      return const Err<AuthSession>(
        StorageFailure(
          'This device cannot protect a local password, so no account was created.',
        ),
      );
    }
    final existing = await _tables.first(_profilesTable, eq: {'email': login});
    if (existing.isErr) return Err<AuthSession>(existing.failureOrNull!);
    if (existing.valueOrNull != null) {
      return Err<AuthSession>(
        BackendFailure(
          'A local account already uses this email.',
          detail: 'local_email_taken',
          code: 'local_email_taken',
        ),
      );
    }
    // Secret first: a row that nobody can sign into is a stranded record, and a
    // failed row insert is undone by deleting the secret again.
    if (!await _vault.write(_secretKey(login), password)) {
      return const Err<AuthSession>(
        StorageFailure('The local password could not be stored on this device.'),
      );
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final id = LocalIds.create();
    final stored = await _tables.insert(_profilesTable, <String, Object?>{
      'id': id,
      'email': login,
      'role': 'parent',
      'display_name': displayName.trim(),
      'created_at': now,
      'updated_at': now,
    });
    if (stored.isErr) {
      await _vault.delete(_secretKey(login));
      return Err<AuthSession>(stored.failureOrNull!);
    }
    _startSession(id, login);
    return Ok<AuthSession>(_session!);
  }

  @override
  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final login = normalizeEmail(email);
    final row = await _tables.first(_profilesTable, eq: {'email': login});
    if (row.isErr) return Err<AuthSession>(row.failureOrNull!);
    final profile = row.valueOrNull;
    final stored = await _vault.read(_secretKey(login));
    // One message for both failure halves: a local gate must not become a way to
    // discover which emails have accounts.
    if (profile == null || stored == null || stored != password) {
      return const Err<AuthSession>(
        AuthFailure('Email or password is not correct.'),
      );
    }
    _startSession(profile['id']! as String, login);
    return Ok<AuthSession>(_session!);
  }

  @override
  Future<Result<AuthSession>> signInWithFirebaseToken(
    String firebaseIdToken,
  ) async {
    return const Err<AuthSession>(
      BlockedFailure(
        'Cloud sign-in is not available in offline mode.',
        missing: 'a configured staging backend and the approved auth bridge',
      ),
    );
  }

  @override
  Future<Result<AuthSession?>> currentSession() async =>
      Ok<AuthSession?>(_session);

  @override
  Future<Result<AuthSession>> refresh() async {
    final session = _session;
    if (session == null) {
      return const Err<AuthSession>(
        AuthFailure('No local session to refresh.', signedOut: true),
      );
    }
    return Ok<AuthSession>(session);
  }

  @override
  Future<Result<void>> signOut() async {
    // Session only. Rows and the stored secret stay: the family data belongs to
    // the parent, not to the login.
    _session = null;
    _states.add(const AuthStateSnapshot(AuthStatusKind.signedOut));
    return okVoid();
  }

  @override
  Stream<AuthStateSnapshot> get states => _states.stream;

  void _startSession(String id, String email) {
    _session = AuthSession(
      userId: id,
      email: email,
      accessToken: 'local:$id',
      role: 'parent',
    );
    _states.add(AuthStateSnapshot(AuthStatusKind.signedIn, session: _session));
  }

  /// Releases the states stream when the offline backend is torn down.
  void dispose() => _states.close();
}
