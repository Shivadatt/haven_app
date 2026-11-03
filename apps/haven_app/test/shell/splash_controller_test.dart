import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/authentication/controllers/splash_controller.dart';
import 'package:haven_core/haven_core.dart';

import '../support/fakes.dart';

/// The splash decides the first route from what the build can reach, so the
/// interesting assertions are *which route* and *how many times*.
void main() {
  const session = AuthSession(
    userId: 'u1',
    email: 'p@example.invalid',
    accessToken: 'token',
  );

  SplashController controller({
    BackendReadiness readiness = BackendReadiness.configured,
    FakeUserAuth? auth,
    FakeProfileStore? profiles,
    required List<String> routes,
  }) => SplashController(
    connect: () async => HavenBackendHandle(BackendStatus(readiness)),
    auth: () => auth ?? FakeUserAuth(session),
    profiles: () => profiles ?? FakeProfileStore({'u1': null}),
    goTo: routes.add,
  );

  test(
    'a build with no backend stalls instead of opening an empty dashboard',
    () async {
      final routes = <String>[];
      final subject = controller(
        readiness: BackendReadiness.notConfigured,
        routes: routes,
      );

      await subject.start();

      expect(subject.stage.value, SplashStage.stalled);
      expect(routes, isEmpty);
      expect(subject.message, contains('no staging project configured'));
    },
  );

  test(
    'Firebase alone is not a session: the app holds rather than signs in',
    () async {
      final routes = <String>[];
      final auth = FakeUserAuth(session);
      final subject = controller(
        readiness: BackendReadiness.firebaseOnly,
        auth: auth,
        routes: routes,
      );

      await subject.start();

      expect(subject.stage.value, SplashStage.stalled);
      expect(auth.currentCallCount, 0, reason: 'no Supabase client to ask');
      expect(routes, isEmpty);
    },
  );

  test('signed out goes to sign-in', () async {
    final routes = <String>[];
    final subject = controller(auth: FakeUserAuth(null), routes: routes);

    await subject.start();

    expect(subject.stage.value, SplashStage.away);
    expect(routes, [AppRoutes.signIn]);
  });

  test('a signed-in account with no profile row starts onboarding', () async {
    final routes = <String>[];
    final profiles = FakeProfileStore({'u1': null});
    final subject = controller(profiles: profiles, routes: routes);

    await subject.start();

    expect(subject.stage.value, SplashStage.away);
    expect(routes, [AppRoutes.onboarding]);
    expect(profiles.loadCount, 1);
  });

  test('an existing profile goes straight to the dashboard', () async {
    final routes = <String>[];
    final subject = controller(
      profiles: FakeProfileStore({
        'u1': {'role': 'parent'},
      }),
      routes: routes,
    );

    await subject.start();

    expect(routes, [AppRoutes.dashboard]);
  });

  test('a failed sign-in read is a stall, not a sign-out', () async {
    final routes = <String>[];
    final profiles = FakeProfileStore({'u1': null});
    final subject = controller(
      auth: FakeUserAuth(null)
        ..failWith = const NetworkFailure(
          'Could not reach the sign-in service.',
        ),
      profiles: profiles,
      routes: routes,
    );

    await subject.start();

    expect(subject.stage.value, SplashStage.stalled);
    expect(subject.message, contains('Could not reach'));
    expect(routes, isEmpty);
    expect(profiles.loadCount, 0);
  });

  test('a failed profile read is a stall, not the provisioning gap', () async {
    final routes = <String>[];
    final subject = controller(profiles: FakeProfileStore({}), routes: routes);

    await subject.start();

    expect(subject.stage.value, SplashStage.stalled);
    expect(routes, isEmpty, reason: 'onboarding would hide a network fault');
  });

  test(
    'a blocked Firebase-bridge sign-in never pretends to have a session',
    () async {
      final auth = FakeUserAuth(null);
      final Result<AuthSession> result = await auth.signInWithFirebaseToken(
        'asserted-uid',
      );

      expect(result.isOk, isFalse);
      expect(result.failureOrNull, isA<BlockedFailure>());
    },
  );
}
