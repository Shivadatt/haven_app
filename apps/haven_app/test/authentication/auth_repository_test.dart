import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/authentication/data/auth_repository.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../support/fakes.dart';

/// The repository is the only place identity is decoded, so the mapping rules
/// (trimming, "no profile row yet", failure passthrough) are tested here.
void main() {
  const session = AuthSession(
    userId: 'u1',
    email: 'p@example.invalid',
    accessToken: 'token',
  );

  HavenAuthRepository repo(FakeUserAuth auth, FakeProfileStore profiles) =>
      HavenAuthRepository(auth: () => auth, profiles: () => profiles);

  test('the email is trimmed before it reaches the provider', () async {
    final auth = FakeUserAuth(session);
    await repo(
      auth,
      FakeProfileStore({}),
    ).signIn(email: '  p@example.invalid  ', password: 'hunter2hunter2');

    expect(auth.lastEmail, 'p@example.invalid');
  });

  test('a sign-in failure keeps its own message and type', () async {
    final auth = FakeUserAuth(null)
      ..failWith = const AuthFailure(
        'Your sign-in has expired.',
        signedOut: true,
      );
    final Result<AuthSession> result = await repo(
      auth,
      FakeProfileStore({}),
    ).signIn(email: 'p@example.invalid', password: 'hunter2hunter2');

    expect(result.isOk, isFalse);
    final HavenFailure failure = result.failureOrNull!;
    expect(failure, isA<AuthFailure>());
    expect(failure.message, 'Your sign-in has expired.');
    expect((failure as AuthFailure).signedOut, isTrue);
  });

  test('a missing profile row is a null profile, not an error', () async {
    final Result<Profile?> result = await repo(
      FakeUserAuth(session),
      FakeProfileStore({'u1': null}),
    ).profileFor('u1');

    expect(result.isOk, isTrue);
    expect(result.valueOrNull, isNull);
  });

  test('a profile row is decoded into the typed model', () async {
    final Result<Profile?> result = await repo(
      FakeUserAuth(session),
      FakeProfileStore({
        'u1': {'id': 'u1', 'role': 'parent', 'display_name': 'Rae'},
      }),
    ).profileFor('u1');

    final Profile? profile = result.valueOrNull;
    expect(profile?.displayName, 'Rae');
    expect(profile?.profileRole, ProfileRole.parent);
  });

  test('a profile read failure is passed through, never swallowed', () async {
    final Result<Profile?> result = await repo(
      FakeUserAuth(session),
      FakeProfileStore({}),
    ).profileFor('u1');

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('sign-out clears the session and reports success', () async {
    final subject = repo(FakeUserAuth(session), FakeProfileStore({}));

    expect((await subject.signOut()).isOk, isTrue);
    expect((await subject.currentSession()).valueOrNull, isNull);
  });

  test('the Firebase bridge stays blocked: a UID is not identity', () async {
    final Result<AuthSession> result = await repo(
      FakeUserAuth(session),
      FakeProfileStore({}),
    ).signInWithFirebaseToken('asserted-uid');

    expect(result.isOk, isFalse);
    expect(result.failureOrNull, isA<BlockedFailure>());
  });

  test(
    'a replaced seam is followed, so the post-install client is used',
    () async {
      UserAuth seam = FakeUserAuth(null)
        ..failWith = const NetworkFailure(
          'Sign-in is not available in this build.',
        );
      final subject = HavenAuthRepository(
        auth: () => seam,
        profiles: () => FakeProfileStore({'u1': null}),
      );

      expect(
        (await subject.signIn(email: 'a@b.co', password: 'x')).isOk,
        isFalse,
      );

      seam = FakeUserAuth(session);
      expect(
        (await subject.signIn(email: 'a@b.co', password: 'x')).isOk,
        isTrue,
      );
    },
  );
}
