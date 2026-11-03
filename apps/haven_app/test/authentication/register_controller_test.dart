import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/authentication/controllers/register_controller.dart';
import 'package:haven_app/features/authentication/data/auth_repository.dart';
import 'package:haven_core/haven_core.dart';

import '../support/fakes.dart';
import 'fakes.dart';

void main() {
  const session = AuthSession(
    userId: 'u1',
    email: 'parent@example.invalid',
    accessToken: 'token',
  );

  (RegisterController, List<String>, FakeAuthRepository) build({
    String name = 'Rae',
    String email = 'parent@example.invalid',
    String password = 'hunter2hunter2',
    HavenFailure? failWith,
  }) {
    final repository = FakeAuthRepository(session: session, failWith: failWith);
    final routes = <String>[];
    final subject =
        RegisterController(
            repository: repository,
            goTo: (String route, Object? _) => routes.add(route),
          )
          ..displayName.text = name
          ..email.text = email
          ..password.text = password;
    return (subject, routes, repository);
  }

  test('every field is checked before a request leaves', () async {
    final (subject, routes, repository) = build(name: '', email: 'nope');

    await subject.submit();

    expect(subject.nameError.value, isNotNull);
    expect(subject.emailError.value, isNotNull);
    expect(repository.calls, isEmpty);
    expect(routes, isEmpty);
  });

  test('the trimmed name and email are what reach the provider', () async {
    // Through the real repository, because trimming is the repository's job.
    final auth = FakeUserAuth(session);
    final routes = <String>[];
    final subject =
        RegisterController(
            repository: HavenAuthRepository(
              auth: () => auth,
              profiles: () => FakeProfileStore({'u1': null}),
            ),
            goTo: (String route, Object? _) => routes.add(route),
          )
          ..displayName.text = '  Rae  '
          ..email.text = '  parent@example.invalid '
          ..password.text = 'hunter2hunter2';

    await subject.submit();

    expect(auth.lastDisplayName, 'Rae');
    expect(auth.lastEmail, 'parent@example.invalid');
  });

  test('a rejected password is shown, not swallowed', () async {
    final (subject, routes, _) = build(
      failWith: const ValidationFailure(
        'Pick a longer password.',
        field: 'password',
      ),
    );

    await subject.submit();

    expect(subject.formError.value, 'Pick a longer password.');
    expect(subject.busy.value, isFalse);
    expect(routes, isEmpty);
  });

  test('a new account has no profile row, so onboarding is next', () async {
    final (subject, routes, _) = build();

    await subject.submit();

    expect(routes, [AppRoutes.onboarding]);
    expect(subject.password.text, isEmpty);
  });

  test('a second tap while the first is running sends nothing', () async {
    final (subject, _, repository) = build();
    subject.busy.value = true;

    await subject.submit();

    expect(repository.calls, isEmpty);
  });
}
