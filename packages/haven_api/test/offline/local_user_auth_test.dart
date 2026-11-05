import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// A vault that actually stores, the way `SecureVault` does on a healthy device.
final class _WorkingVault implements SecretVault {
  final Map<String, String> values = {};

  @override
  bool get available => true;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<bool> write(String key, String value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  late LocalTables tables;
  late InMemoryLocalStore store;
  late _WorkingVault vault;
  late LocalUserAuth auth;

  setUp(() {
    store = InMemoryLocalStore();
    tables = LocalTables(store);
    vault = _WorkingVault();
    auth = LocalUserAuth(tables, vault);
  });

  group('local parent account', () {
    test('register creates the profile row and signs the session in', () async {
      final result = await auth.register(
        email: 'Ada@Haven.test',
        password: 'haven123',
        displayName: 'Ada',
      );
      expect(result.isOk, isTrue);
      final profile = await tables.first(
        'profiles',
        eq: {'email': 'ada@haven.test'},
      );
      expect(profile.valueOrNull, isNotNull);
      expect(profile.valueOrNull!['display_name'], 'Ada');
      // Email is folded before it is stored: one account per address.
      expect(profile.valueOrNull!['role'], 'parent');
      expect((await auth.currentSession()).valueOrNull!.email, 'ada@haven.test');
    });

    test('the secret lands in the vault, never in the row', () async {
      await auth.register(
        email: 'a@b.co',
        password: 'haven123',
        displayName: 'A',
      );
      expect(vault.values['local_auth.a@b.co'], 'haven123');
      final profile = await tables.first('profiles', eq: {'email': 'a@b.co'});
      expect(profile.valueOrNull!.containsKey('password'), isFalse);
    });

    test('sign in accepts the right password and rejects the wrong one', () async {
      await auth.register(
        email: 'a@b.co',
        password: 'haven123',
        displayName: 'A',
      );
      await auth.signOut();
      final wrong = await auth.signInWithPassword(
        email: 'a@b.co',
        password: 'nope',
      );
      expect(wrong.isErr, isTrue);
      expect(wrong.failureOrNull, isA<AuthFailure>());
      // The message must not reveal which half failed.
      expect(
        wrong.failureOrNull!.message,
        'Email or password is not correct.',
      );
      final right = await auth.signInWithPassword(
        email: 'a@b.co',
        password: 'haven123',
      );
      expect(right.isOk, isTrue);
    });

    test('a second account with the same email is refused', () async {
      await auth.register(
        email: 'a@b.co',
        password: 'haven123',
        displayName: 'A',
      );
      final again = await auth.register(
        email: 'a@b.co',
        password: 'other123',
        displayName: 'B',
      );
      expect(again.isErr, isTrue);
      expect(
        (again.failureOrNull! as BackendFailure).code,
        'local_email_taken',
      );
    });

    test('an unavailable vault blocks registration, fail-closed', () async {
      final blocked = LocalUserAuth(tables, _NoVault());
      final result = await blocked.register(
        email: 'a@b.co',
        password: 'haven123',
        displayName: 'A',
      );
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<StorageFailure>());
      expect((await tables.count('profiles')).valueOrNull, 0);
    });

    test('validation failures name their field and write nothing', () async {
      final short = await auth.register(
        email: 'a@b.co',
        password: '123',
        displayName: 'A',
      );
      expect(short.failureOrNull, isA<ValidationFailure>());
      expect((short.failureOrNull! as ValidationFailure).field, 'password');
      expect((await tables.count('profiles')).valueOrNull, 0);
    });

    test('sign-out keeps the profile and the secret', () async {
      await auth.register(
        email: 'a@b.co',
        password: 'haven123',
        displayName: 'A',
      );
      await auth.signOut();
      expect((await auth.currentSession()).valueOrNull, isNull);
      expect(
        (await tables.first('profiles', eq: {'email': 'a@b.co'})).valueOrNull,
        isNotNull,
      );
      expect(vault.values['local_auth.a@b.co'], 'haven123');
    });

    test('the account survives a store reopen into a new auth object', () async {
      await auth.register(
        email: 'a@b.co',
        password: 'haven123',
        displayName: 'A',
      );
      final reopened = LocalUserAuth(
        LocalTables(store),
        vault,
      ); // same vault, same document
      final signed = await reopened.signInWithPassword(
        email: 'a@b.co',
        password: 'haven123',
      );
      expect(signed.isOk, isTrue, reason: 'a local account is durable');
    });

    test('cloud token sign-in says it is blocked, not proxied', () async {
      final result = await auth.signInWithFirebaseToken('whatever');
      expect(result.failureOrNull, isA<BlockedFailure>());
    });

    test('states emits signed-in then signed-out', () async {
      final seen = <AuthStatusKind>[];
      final sub = auth.states.listen((s) => seen.add(s.kind));
      await auth.register(
        email: 'a@b.co',
        password: 'haven123',
        displayName: 'A',
      );
      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(seen, [AuthStatusKind.signedIn, AuthStatusKind.signedOut]);
      await sub.cancel();
    });
  });
}

/// Reused from the credential seams test, mirrored for one use: writes fail.
final class _NoVault implements SecretVault {
  @override
  bool get available => false;

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<bool> write(String key, String value) async => false;

  @override
  Future<void> delete(String key) async {}
}
