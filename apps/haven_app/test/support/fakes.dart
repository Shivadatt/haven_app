// ignore_for_file: use_null_aware_elements

import 'dart:async';

import 'package:haven_api/haven_api.dart';
import 'package:haven_app/core/storage/preferences_store.dart';
import 'package:haven_core/haven_core.dart';

/// Hand-written fakes. The app tests the seams, not the SDK, so no mocking
/// package is involved — see `docs/implementation/00-app-contract.md`.
class FakeUserAuth implements UserAuth {
  FakeUserAuth(this._session);

  AuthSession? _session;
  int currentCallCount = 0;
  HavenFailure? failWith;

  /// What the provider was asked for. The password is deliberately not
  /// recorded: a fake that holds a credential invites it into a debug dump.
  String? lastEmail;
  String? lastDisplayName;

  @override
  Future<Result<AuthSession?>> currentSession() async {
    currentCallCount++;
    final HavenFailure? failure = failWith;
    if (failure != null) return Err(failure);
    return Ok(_session);
  }

  Result<AuthSession> _answer(String email, {String? displayName}) {
    lastEmail = email;
    lastDisplayName = displayName;
    final HavenFailure? failure = failWith;
    if (failure != null) return Err(failure);
    return Ok(
      _session ??
          const AuthSession(
            userId: 'u1',
            email: 'p@example.invalid',
            accessToken: 't',
          ),
    );
  }

  @override
  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  }) async => _answer(email);

  @override
  Future<Result<AuthSession>> register({
    required String email,
    required String password,
    required String displayName,
  }) async => _answer(email, displayName: displayName);

  @override
  Future<Result<AuthSession>> signInWithFirebaseToken(
    String firebaseIdToken,
  ) async => blocked('fake: mapping not loaded');

  @override
  Future<Result<AuthSession>> refresh() async =>
      _session == null ? const Err(AuthFailure('No session.')) : Ok(_session!);

  @override
  Future<Result<void>> signOut() async {
    _session = null;
    return okVoid();
  }

  @override
  Stream<AuthStateSnapshot> get states => Stream<AuthStateSnapshot>.value(
    AuthStateSnapshot(AuthStatusKind.unknown),
  );
}

class FakeProfileStore implements ProfileStore {
  FakeProfileStore(this.rows);

  /// `userId -> row`. A present null is "signed in, no profile yet"; a missing
  /// key is the read itself failing.
  final Map<String, Map<String, Object?>?> rows;
  int loadCount = 0;
  String? lastDisplayName;

  /// Returned instead of a successful write, for the refusal the parent has to
  /// read.
  HavenFailure? updateFailWith;

  @override
  Future<Result<Map<String, Object?>?>> load(String userId) async {
    loadCount++;
    if (!rows.containsKey(userId)) {
      return Err(const NetworkFailure('Could not read the profile.'));
    }
    return Ok(rows[userId]);
  }

  @override
  Future<Result<void>> updateDisplayName(
    String userId,
    String displayName,
  ) async {
    lastDisplayName = displayName;
    final HavenFailure? failure = updateFailWith;
    return failure == null ? okVoid() : Err<void>(failure);
  }

  @override
  Future<Result<void>> createProfile({
    required String userId,
    required String displayName,
    String? email,
    String role = 'parent',
  }) async {
    rows[userId] = {
      'id': userId,
      'role': role,
      'display_name': displayName,
      if (email != null) 'email': email,
    };
    return okVoid();
  }
}

/// A vault that reports whatever the test needs it to.
class FakeVault implements SecretVault {
  FakeVault({this.available = true});

  @override
  bool available;

  final Map<String, String> stored = {};
  int writeCount = 0;

  @override
  Future<String?> read(String key) async => stored[key];

  @override
  Future<bool> write(String key, String value) async {
    writeCount++;
    if (!available) return false;
    stored[key] = value;
    return true;
  }

  @override
  Future<void> delete(String key) async => stored.remove(key);
}

/// Preferences that keep what they are told, unless the test says the phone
/// refused.
class FakePreferencesStore implements PreferencesStore {
  FakePreferencesStore({this.acceptsWrites = true, Map<String, String>? seed})
    : stored = {...?seed};

  final bool acceptsWrites;
  final Map<String, String> stored;
  final List<String> readKeys = [];
  int writeCount = 0;

  @override
  Future<String?> read(String key) async {
    readKeys.add(key);
    return stored[key];
  }

  @override
  Future<bool> write(String key, String value) async {
    writeCount++;
    if (!acceptsWrites) return false;
    stored[key] = value;
    return true;
  }
}
