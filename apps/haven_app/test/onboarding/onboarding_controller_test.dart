import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/onboarding/controllers/onboarding_controller.dart';
import 'package:haven_core/haven_core.dart';

import '../authentication/fakes.dart';
import 'fakes.dart';

void main() {
  const session = AuthSession(
    userId: 'u1',
    email: 'parent@example.invalid',
    accessToken: 'token',
  );

  (OnboardingController, List<String>) build({
    FakeAuthRepository? auth,
    FakeOnboardingRepository? repository,
    String family = 'Rivera household',
  }) {
    final routes = <String>[];
    final subject = OnboardingController(
      repository: repository ?? FakeOnboardingRepository(),
      auth: auth ?? FakeAuthRepository(session: session),
      goTo: (String route, Object? _) => routes.add(route),
    )..familyName.text = family;
    return (subject, routes);
  }

  OnboardingController ready({
    FakeAuthRepository? auth,
    FakeOnboardingRepository? repository,
    String family = 'Rivera household',
  }) {
    final subject = build(
      auth: auth,
      repository: repository,
      family: family,
    ).$1;
    subject.acknowledged.value = true;
    subject.continueFromExplain();
    return subject;
  }

  test('the explanation is the first thing, and it is a gate', () {
    final (subject, _) = build();

    expect(subject.step.value, OnboardingStep.explain);
    subject.continueFromExplain();

    expect(subject.step.value, OnboardingStep.explain);
    expect(subject.message.value, 'Tick the box to say you have read this.');
  });

  test('reading it is enough to reach the setup step', () {
    final (subject, _) = build();
    subject.acknowledged.value = true;

    subject.continueFromExplain();

    expect(subject.step.value, OnboardingStep.setup);
    expect(subject.message.value, isNull);
  });

  test('role first, family second, then the dashboard', () async {
    final repository = FakeOnboardingRepository();
    final (subject, routes) = build(repository: repository);
    subject.acknowledged.value = true;
    subject.continueFromExplain();

    await subject.finish();

    expect(repository.calls, ['role', 'family']);
    expect(repository.lastFamilyName, 'Rivera household');
    expect(routes, [AppRoutes.dashboard]);
    expect(subject.isBusy, isFalse);
  });

  test('nobody signed in means nothing is written', () async {
    final repository = FakeOnboardingRepository();
    final subject = ready(auth: FakeAuthRepository(), repository: repository);

    await subject.finish();

    expect(repository.calls, isEmpty);
    expect(subject.message.value, contains('cannot tell who is signing up'));
  });

  test('a session read that fails says so in its own words', () async {
    final repository = FakeOnboardingRepository();
    final subject = ready(
      auth: FakeAuthRepository(
        sessionFailWith: const NetworkFailure('The internet is unreachable.'),
      ),
      repository: repository,
    );

    await subject.finish();

    expect(subject.message.value, 'The internet is unreachable.');
    expect(repository.calls, isEmpty);
  });

  test('a refused role stops before the family is made', () async {
    final repository = FakeOnboardingRepository()
      ..roleFailWith = const BackendFailure(
        'Sign in with a parent account.',
        code: 'not_a_parent',
      );
    final (subject, routes) = build(repository: repository);
    subject.acknowledged.value = true;
    subject.continueFromExplain();

    await subject.finish();

    expect(repository.calls, ['role']);
    expect(subject.message.value, 'Sign in with a parent account.');
    expect(subject.isBusy, isFalse);
    expect(routes, isEmpty);
  });

  test('a refused family keeps the parent on setup', () async {
    final repository = FakeOnboardingRepository()
      ..familyFailWith = const ValidationFailure(
        'Give your family a name.',
        field: 'family_name',
      );
    final (subject, routes) = build(repository: repository, family: '   ');
    subject.acknowledged.value = true;
    subject.continueFromExplain();

    await subject.finish();

    expect(subject.message.value, 'Give your family a name.');
    expect(routes, isEmpty);
  });

  test('a second tap while the first is in flight sends nothing', () async {
    final repository = FakeOnboardingRepository();
    final subject = ready(repository: repository)..busy.value = true;

    await subject.finish();

    expect(repository.calls, isEmpty);
  });
}
