import 'package:flutter_test/flutter_test.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/account/controllers/account_controller.dart';
import 'package:haven_app/features/account/data/account_repository.dart';

import 'fakes.dart';

void main() {
  const profile = Profile(id: 'u1', role: 'parent', displayName: 'Rae');
  final AccountInfo info = AccountInfo(
    userId: 'u1',
    email: 'parent@example.invalid',
    profile: profile,
  );

  (AccountController, List<(String, Object?)>) build(
    FakeAccountRepository repo,
  ) {
    final nav = <(String, Object?)>[];
    final subject = AccountController(
      repository: repo,
      goTo: (String route, Object? arg) => nav.add((route, arg)),
    );
    return (subject, nav);
  }

  test('loading fills the name field and reads the three refusals', () async {
    final (subject, _) = build(FakeAccountRepository(info: info));

    await subject.load();

    expect(subject.isLoading.value, isFalse);
    expect(subject.account.value!.valueOrNull!.hasProfile, isTrue);
    expect(subject.displayName.text, 'Rae');
    expect(subject.canSave, isTrue);
    expect(subject.passwordChange.value, isA<BlockedFailure>());
    expect(subject.emailChange.value, isA<BlockedFailure>());
    expect(subject.accountDeletion.value, isA<BlockedFailure>());
  });

  test('a load that fails is kept as a failure, not cleared', () async {
    final repo = FakeAccountRepository()
      ..loadFailWith = const NetworkFailure('No connection.');
    final (subject, _) = build(repo);

    await subject.load();

    expect(subject.isLoading.value, isFalse);
    expect(subject.account.value!.failureOrNull, isA<NetworkFailure>());
    expect(subject.displayName.text, isEmpty);
  });

  test('an account with no row cannot be renamed from here', () async {
    final repo = FakeAccountRepository(
      info: const AccountInfo(userId: 'u1', email: 'p@example.invalid'),
    );
    final (subject, _) = build(repo);

    await subject.load();

    expect(subject.canSave, isFalse);
    subject.displayName.text = 'Rae';
    await subject.save();
    expect(repo.calls, ['load']);
  });

  test(
    'saving writes the name and reloads what the backend now holds',
    () async {
      final repo = FakeAccountRepository(info: info);
      final (subject, _) = build(repo);
      await subject.load();
      subject.displayName.text = 'Rae Rivera';

      await subject.save();

      expect(repo.lastDisplayName, 'Rae Rivera');
      expect(repo.calls.where((c) => c == 'load').length, 2);
      expect(subject.message.value, isNull);
      expect(subject.busy.value, isFalse);
    },
  );

  test('a refused save says so and stays on the screen', () async {
    final repo = FakeAccountRepository(info: info)
      ..renameFailWith = const ValidationFailure(
        'Use at least 2 characters.',
        field: 'display_name',
      );
    final (subject, _) = build(repo);
    await subject.load();
    subject.displayName.text = 'R';

    await subject.save();

    expect(subject.message.value, 'Use at least 2 characters.');
    expect(subject.busy.value, isFalse);
    expect(repo.calls.where((c) => c == 'load').length, 1);
  });

  test('signing out ends the session and lands on the explanation', () async {
    final (subject, nav) = build(FakeAccountRepository(info: info));
    await subject.load();

    await subject.signOut();

    expect(nav, [(AppRoutes.sessionEnded, 'You are signed out of Haven.')]);
  });

  test('a sign-out the backend refuses keeps the parent signed in', () async {
    final repo = FakeAccountRepository(info: info)
      ..signOutFailWith = const NetworkFailure('No connection.');
    final (subject, nav) = build(repo);
    await subject.load();

    await subject.signOut();

    expect(subject.message.value, 'No connection.');
    expect(nav, isEmpty);
  });

  test('setup is where an account with no record has to go', () async {
    final (subject, nav) = build(FakeAccountRepository(info: info));

    subject.goToSetup();

    expect(nav.single.$1, AppRoutes.onboarding);
    expect(nav.single.$2, isNull);
  });

  test('a second save while the first is running does nothing', () async {
    final repo = FakeAccountRepository(info: info);
    final (subject, _) = build(repo);
    await subject.load();
    subject.busy.value = true;

    await subject.save();

    expect(repo.calls.contains('rename'), isFalse);
  });
}
