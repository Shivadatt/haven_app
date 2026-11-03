import 'dart:async';

import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';
import 'package:haven_app/features/authentication/data/auth_repository.dart';

/// A repository that answers exactly what the test tells it to. No SDK, no
/// network — the app's identity logic is what is under test.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.session,
    this.profile,
    this.failWith,
    this.profileFailWith,
    this.sessionFailWith,
  });

  AuthSession? session;
  Profile? profile;

  /// Returned instead of a success for identity calls.
  HavenFailure? failWith;

  /// Returned instead of the "who is signed in" read, which can fail on its own.
  HavenFailure? sessionFailWith;

  /// Returned instead of a profile, for the lookup that follows sign-in —
  /// separate because a session can succeed while the profile read fails.
  HavenFailure? profileFailWith;

  final List<String> calls = [];
  String? lastEmail;
  String? lastDisplayName;
  int signOutCount = 0;

  /// Driven by the test, because a session that ends on its own is the case
  /// worth checking.
  final StreamController<AuthStateSnapshot> _states =
      StreamController<AuthStateSnapshot>.broadcast();

  void emit(AuthStatusKind kind) => _states.add(AuthStateSnapshot(kind));

  Future<void> finishStates() => _states.close();

  @override
  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  }) async {
    calls.add('signIn');
    lastEmail = email;
    final HavenFailure? failure = failWith;
    if (failure != null) return Err(failure);
    final AuthSession? value = session;
    return value == null
        ? const Err(AuthFailure('Email or password is not recognised.'))
        : Ok(value);
  }

  @override
  Future<Result<AuthSession>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    calls.add('register');
    lastEmail = email;
    lastDisplayName = displayName;
    final HavenFailure? failure = failWith;
    if (failure != null) return Err(failure);
    final AuthSession? value = session;
    return value == null
        ? const Err(
            ValidationFailure('Pick a longer password.', field: 'password'),
          )
        : Ok(value);
  }

  @override
  Future<Result<AuthSession>> signInWithFirebaseToken(
    String firebaseIdToken,
  ) async => blocked('fake: identity mapping not loaded');

  @override
  Future<Result<AuthSession?>> currentSession() async {
    final HavenFailure? failure = sessionFailWith;
    if (failure != null) return Err<AuthSession?>(failure);
    return Ok<AuthSession?>(session);
  }

  @override
  Future<Result<void>> signOut() async {
    signOutCount++;
    session = null;
    return okVoid();
  }

  @override
  Stream<AuthStateSnapshot> get states => _states.stream;

  @override
  Future<Result<Profile?>> profileFor(String userId) async {
    calls.add('profileFor');
    final HavenFailure? failure = profileFailWith;
    if (failure != null) return Err<Profile?>(failure);
    return Ok<Profile?>(profile);
  }
}
