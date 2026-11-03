import 'dart:async';

import 'package:haven_core/haven_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_contracts.dart';
import 'failure_mapper.dart';

/// `UserAuth` over Supabase Auth. Supabase is the session authority: the token
/// returned here is what every later request is signed with.
///
/// Firebase's own token is only ever *presented* to Supabase (Third-Party Auth),
/// and the exchange is blocked until A13 is signed and profile provisioning
/// exists — see [signInWithFirebaseToken].
final class SupabaseUserAuth implements UserAuth {
  SupabaseUserAuth(this._client);

  final SupabaseClient _client;
  final StreamController<AuthStateSnapshot> _states =
      StreamController<AuthStateSnapshot>.broadcast();
  StreamSubscription<AuthState>? _sub;

  AuthSession _map(Session session) => AuthSession(
    userId: session.user.id,
    email: session.user.email,
    accessToken: session.accessToken,
    // `profiles.role` is not part of an auth reply; the caller loads it via
    // ProfileStore and must handle a missing profile row.
    role: null,
    expiresAt: _expiry(session.expiresAt),
  );

  /// gotrue reports `expires_at` in epoch seconds.
  static DateTime? _expiry(int? seconds) => seconds == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

  @override
  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final reply = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return _sessionOrFailure(reply);
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<AuthSession>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final reply = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName.trim()},
      );
      if (reply.session == null) {
        // Email confirmation is on for this project's provider configuration,
        // so sign-up returns a user but no session. Saying "signed in" would be
        // a fabrication.
        return Err(
          AuthFailure(
            'Almost done: check that inbox for the link to finish creating the account.',
            detail: 'signUp returned no session (confirmation pending)',
          ),
        );
      }
      return _sessionOrFailure(reply);
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  /// NOT IMPLEMENTED — BY APPROVAL, NOT BY ABILITY.
  ///
  /// The owner chose the Third-Party Auth bridge (S2-EXEC-08 §1) but `A13` is
  /// unsigned, the mapping table `A3d` is unapproved and unloaded, and no
  /// evidenced action provisions a `profiles` row for a third-party identity.
  /// Completing this locally would mean either asserting a client-side Firebase
  /// UID as identity — explicitly forbidden — or inventing a provisioning trigger.
  @override
  Future<Result<AuthSession>> signInWithFirebaseToken(
    String firebaseIdToken,
  ) async => blocked(
    'A13 unsigned + firebase_identity_mapping not loaded + profile provisioning gap',
    requirement:
        'Sign-in with a Firebase account is not available on this build yet.',
  );

  @override
  Future<Result<AuthSession?>> currentSession() async {
    try {
      final session = _client.auth.currentSession;
      return Ok(session == null ? null : _map(session));
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<AuthSession>> refresh() async {
    try {
      final session = await _client.auth.refreshSession();
      return _sessionOrFailure(session);
    } catch (error) {
      final failure = mapSupabaseError(error);
      return Err(
        failure is AuthFailure
            ? failure
            : AuthFailure('Could not renew the session.', detail: '$error'),
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return okVoid();
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Stream<AuthStateSnapshot> get states {
    if (_sub == null) {
      _sub = _client.auth.onAuthStateChange.listen(
        (event) {
          final session = event.session;
          _states.add(switch (event.event) {
            AuthChangeEvent.signedOut => const AuthStateSnapshot(
              AuthStatusKind.signedOut,
            ),
            AuthChangeEvent.signedIn ||
            AuthChangeEvent.initialSession ||
            AuthChangeEvent.tokenRefreshed ||
            AuthChangeEvent.userUpdated =>
              session == null
                  ? const AuthStateSnapshot(AuthStatusKind.signedOut)
                  : AuthStateSnapshot(
                      AuthStatusKind.signedIn,
                      session: _map(session),
                    ),
            AuthChangeEvent.passwordRecovery => const AuthStateSnapshot(
              AuthStatusKind.unknown,
            ),
            _ => AuthStateSnapshot(
              AuthStatusKind.unknown,
              session: session == null ? null : _map(session),
            ),
          });
        },
        onError: (Object error) =>
            _states.add(AuthStateSnapshot(AuthStatusKind.expired)),
      );
    }
    return _states.stream;
  }

  Result<AuthSession> _sessionOrFailure(AuthResponse reply) {
    final session = reply.session;
    if (session == null) {
      return const Err(AuthFailure('No session was issued.'));
    }
    return Ok(_map(session));
  }

  void dispose() {
    unawaited(_sub?.cancel());
    unawaited(_states.close());
  }
}
