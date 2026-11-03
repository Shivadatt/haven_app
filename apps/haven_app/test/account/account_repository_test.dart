import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_app/features/account/data/account_repository.dart';

import '../support/fakes.dart';

void main() {
  const session = AuthSession(
    userId: 'u1',
    email: 'parent@example.invalid',
    accessToken: 'token',
  );
  const row = {'id': 'u1', 'role': 'parent', 'display_name': 'Rae'};

  late FakeUserAuth auth;
  late FakeProfileStore profiles;
  late HavenAccountRepository subject;

  void build({
    Map<String, Map<String, Object?>?>? rows,
    bool signedOut = false,
  }) {
    auth = FakeUserAuth(signedOut ? null : session);
    profiles = FakeProfileStore(rows ?? {'u1': row});
    subject = HavenAccountRepository(
      auth: () => auth,
      profiles: () => profiles,
    );
  }

  T must<T>(HavenFailure? failure) => failure as T;

  group('load', () {
    test('gives the screen the session email and the profile row', () async {
      build();
      final result = await subject.load();

      expect(result.failureOrNull, isNull);
      expect(result.valueOrNull!.email, 'parent@example.invalid');
      expect(result.valueOrNull!.profile!.displayName, 'Rae');
      expect(result.valueOrNull!.role?.wire, 'parent');
    });

    test('a signed-in account with no row is a state, not an error', () async {
      build(rows: {'u1': null});
      final result = await subject.load();

      expect(result.failureOrNull, isNull);
      expect(result.valueOrNull!.hasProfile, isFalse);
    });

    test('no session is reported as signed out', () async {
      build(signedOut: true);
      final failure = (await subject.load()).failureOrNull;

      expect(failure, isA<AuthFailure>());
      expect(must<AuthFailure>(failure).signedOut, isTrue);
    });

    test('a profile read that fails is passed through', () async {
      build(rows: {});
      expect((await subject.load()).failureOrNull, isA<NetworkFailure>());
    });
  });

  group('rename', () {
    test('trims before writing', () async {
      build();
      expect(
        (await subject.rename(displayName: '  Rae  ')).failureOrNull,
        isNull,
      );
      expect(profiles.lastDisplayName, 'Rae');
    });

    test('a name too short never reaches the store', () async {
      build();
      final failure = (await subject.rename(displayName: 'R')).failureOrNull;

      expect(failure, isA<ValidationFailure>());
      expect(must<ValidationFailure>(failure).field, 'display_name');
      expect(profiles.lastDisplayName, isNull);
    });

    test('renaming without a session says signed out', () async {
      build(signedOut: true);
      final failure = (await subject.rename(displayName: 'Rae')).failureOrNull;

      expect(failure, isA<AuthFailure>());
      expect(must<AuthFailure>(failure).signedOut, isTrue);
    });

    test(
      'a write the backend refuses is the message the parent reads',
      () async {
        build();
        profiles.updateFailWith = const PermissionFailure(
          'You can only change your own name.',
        );

        final failure = (await subject.rename(
          displayName: 'Rae',
        )).failureOrNull;
        expect(failure!.message, 'You can only change your own name.');
      },
    );
  });

  test('sign-out goes through the auth seam', () async {
    build();
    expect((await subject.signOut()).failureOrNull, isNull);
    expect((await subject.load()).failureOrNull, isA<AuthFailure>());
  });

  group('abilities with no approved contract', () {
    test('each one answers blocked, with the gap named', () async {
      build();
      final results = await Future.wait([
        subject.passwordChange(),
        subject.emailChange(),
        subject.accountDeletion(),
      ]);

      for (final result in results) {
        final failure = result.failureOrNull;
        expect(failure, isA<BlockedFailure>());
        expect(
          must<BlockedFailure>(failure).detail,
          contains('BLOCKED — SPECIFICATION REQUIRED'),
        );
      }
    });

    test('the parent-facing line explains what is missing', () async {
      build();
      expect(
        (await subject.passwordChange()).failureOrNull!.message,
        'Haven cannot change your password yet.',
      );
    });
  });

  test(
    'a replaced seam is followed, so the post-install client is used',
    () async {
      build();
      final installed = FakeUserAuth(null);
      auth = installed;

      expect((await subject.load()).failureOrNull, isA<AuthFailure>());
      expect(installed.currentCallCount, 1);
    },
  );
}
