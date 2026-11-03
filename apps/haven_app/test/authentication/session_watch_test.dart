import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/authentication/services/session_watch.dart';

import 'fakes.dart';

/// The session ends without the parent asking: it expires, it is revoked, or it
/// is signed out elsewhere. Each case has to reach the one page that explains it.
void main() {
  (SessionWatch, List<List<Object?>>) watch(
    FakeAuthRepository repository, {
    String on = AppRoutes.dashboard,
  }) {
    final navigations = <List<Object?>>[];
    final subject = SessionWatch(
      repository: repository,
      currentRoute: () => on,
      onLost: (String route, Object? arg) => navigations.add([route, arg]),
    );
    return (subject, navigations);
  }

  Future<void> started(SessionWatch subject) async {
    subject.onInit();
    // The subscription is created inside onInit, so one event loop must pass
    // before anything emitted is actually delivered.
    await Future<void>.delayed(Duration.zero);
  }

  test('an expired session says so, once', () async {
    final repository = FakeAuthRepository();
    final (subject, navigations) = watch(repository);
    await started(subject);

    repository.emit(AuthStatusKind.expired);
    await Future<void>.delayed(Duration.zero);

    expect(navigations, [
      [AppRoutes.sessionEnded, 'Your sign-in expired.'],
    ]);
    await repository.finishStates();
    subject.onClose();
  });

  test('a signed-out session is reported, not silently bounced', () async {
    final repository = FakeAuthRepository();
    final (subject, navigations) = watch(repository);
    await started(subject);

    repository.emit(AuthStatusKind.signedOut);
    await Future<void>.delayed(Duration.zero);

    expect(navigations.single[0], AppRoutes.sessionEnded);
    expect(navigations.single[1], 'You are signed out.');
    await repository.finishStates();
    subject.onClose();
  });

  test('a missing profile is stated as the provisioning gap it is', () async {
    final repository = FakeAuthRepository();
    final (subject, navigations) = watch(repository);
    await started(subject);

    repository.emit(AuthStatusKind.profileMissing);
    await Future<void>.delayed(Duration.zero);

    expect(
      navigations.single[1],
      contains('no profile yet'),
      reason: 'the gap is documented; the screen must name it',
    );
    await repository.finishStates();
    subject.onClose();
  });

  test('being on the sign-in page already is the answer', () async {
    final repository = FakeAuthRepository();
    final (subject, navigations) = watch(repository, on: AppRoutes.signIn);
    await started(subject);

    repository.emit(AuthStatusKind.signedOut);
    await Future<void>.delayed(Duration.zero);

    expect(navigations, isEmpty);
    await repository.finishStates();
    subject.onClose();
  });

  test('a live session moves nobody', () async {
    final repository = FakeAuthRepository();
    final (subject, navigations) = watch(repository);
    await started(subject);

    repository.emit(AuthStatusKind.signedIn);
    await Future<void>.delayed(Duration.zero);

    expect(navigations, isEmpty);
    await repository.finishStates();
    subject.onClose();
  });

  test('closing stops the listening', () async {
    final repository = FakeAuthRepository();
    final (subject, navigations) = watch(repository);
    await started(subject);
    subject.onClose();

    repository.emit(AuthStatusKind.expired);
    await Future<void>.delayed(Duration.zero);

    expect(navigations, isEmpty);
    await repository.finishStates();
  });
}
