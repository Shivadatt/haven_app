import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/authentication/controllers/sign_in_controller.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'fakes.dart';

void main() {
  const session = AuthSession(
    userId: 'u1',
    email: 'p@example.invalid',
    accessToken: 'token',
  );
  const profile = Profile(id: 'u1', role: 'parent', displayName: 'Rae');

  (SignInController, List<String>) build({
    FakeAuthRepository? repository,
    String email = 'parent@example.invalid',
    String password = 'hunter2hunter2',
  }) {
    final routes = <String>[];
    final subject =
        SignInController(
            repository: repository ?? FakeAuthRepository(session: session),
            goTo: (String route, Object? _) => routes.add(route),
          )
          ..email.text = email
          ..password.text = password;
    return (subject, routes);
  }

  test('a blank email is caught locally, before any request', () async {
    final repository = FakeAuthRepository(session: session);
    final (subject, routes) = build(repository: repository, email: '');

    await subject.submit();

    expect(subject.emailError.value, isNotNull);
    expect(repository.calls, isEmpty);
    expect(routes, isEmpty);
  });

  test('an incomplete address names what to fix', () async {
    final (subject, _) = build(email: 'not-an-address');

    await subject.submit();

    expect(subject.emailError.value, contains('complete email address'));
  });

  test('a short password is rejected before the network is tried', () async {
    final repository = FakeAuthRepository(session: session);
    final (subject, _) = build(repository: repository, password: 'short');

    await subject.submit();

    expect(subject.passwordError.value, contains('8 characters'));
    expect(repository.calls, isEmpty);
  });

  test('the backend answer is what the parent reads', () async {
    final repository = FakeAuthRepository(
      failWith: const AuthFailure('Email or password is not recognised.'),
    );
    final (subject, routes) = build(repository: repository);

    await subject.submit();

    expect(subject.formError.value, 'Email or password is not recognised.');
    expect(subject.busy.value, isFalse);
    expect(routes, isEmpty);
  });

  test('an existing profile lands on the dashboard', () async {
    final (subject, routes) = build(
      repository: FakeAuthRepository(session: session, profile: profile),
    );

    await subject.submit();

    expect(routes, [AppRoutes.dashboard]);
    expect(subject.busy.value, isFalse);
  });

  test('a signed-in account with no profile row starts onboarding', () async {
    final (subject, routes) = build(
      repository: FakeAuthRepository(session: session, profile: null),
    );

    await subject.submit();

    expect(routes, [AppRoutes.onboarding]);
  });

  test(
    'a profile read failure still enters the app, on the dashboard',
    () async {
      final (subject, routes) = build(
        repository: FakeAuthRepository(
          session: session,
          profileFailWith: const NetworkFailure('Could not read the profile.'),
        ),
      );

      await subject.submit();

      expect(subject.formError.value, isNull);
      expect(routes, [AppRoutes.dashboard]);
    },
  );

  test('a second tap while a request is in flight sends nothing', () async {
    final repository = FakeAuthRepository(session: session, profile: profile);
    final (subject, routes) = build(repository: repository);
    subject.busy.value = true;

    await subject.submit();

    expect(repository.calls, isEmpty);
    expect(routes, isEmpty);
  });

  test(
    'the password is cleared from the field after a successful sign-in',
    () async {
      final (subject, _) = build();

      await subject.submit();

      expect(subject.password.text, isEmpty);
    },
  );
}
