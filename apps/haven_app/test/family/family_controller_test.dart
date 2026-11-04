import 'package:flutter_test/flutter_test.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/family/controllers/family_controller.dart';

import 'fakes.dart';

void main() {
  (FamilyController, List<(String, String, Object?)>) build(
    FakeFamilyRepository repo,
  ) {
    // push and replace are recorded separately: which one a screen uses is the
    // difference between a parent being able to come back and not.
    final nav = <(String, String, Object?)>[];
    final subject = FamilyController(
      repository: repo,
      push: (String route, Object? arg) => nav.add(('push', route, arg)),
      replace: (String route, Object? arg) => nav.add(('replace', route, arg)),
    );
    return (subject, nav);
  }

  test('loading fills the name field and reads the two refusals', () async {
    final (subject, _) = build(FakeFamilyRepository(bundle: bundle()));

    await subject.load();

    expect(subject.isLoading.value, isFalse);
    expect(subject.familyName.text, 'Rivera');
    expect(subject.canSave, isTrue);
    expect(subject.inviteParent.value, isA<BlockedFailure>());
    expect(subject.removeParent.value, isA<BlockedFailure>());
  });

  test('a load that fails stays a failure and disables saving', () async {
    final (subject, _) = build(
      FakeFamilyRepository()..loadFailWith = const NetworkFailure('No signal.'),
    );

    await subject.load();

    expect(subject.family.value!.failureOrNull, isA<NetworkFailure>());
    expect(subject.canSave, isFalse);
    expect(subject.familyName.text, isEmpty);
  });

  test('an account with no family is not offered a dead form', () async {
    final (subject, _) = build(FakeFamilyRepository(bundle: null));

    await subject.load();

    expect(subject.family.value!.valueOrNull, isNull);
    expect(subject.canSave, isFalse);
  });

  test('saving writes the edited name and re-reads', () async {
    final repo = FakeFamilyRepository(bundle: bundle());
    final (subject, _) = build(repo);
    await subject.load();

    subject.familyName.text = 'The Riveras';
    await subject.save();

    expect(repo.lastName, 'The Riveras');
    expect(repo.calls, [
      'load',
      'inviteParent',
      'removeParent',
      'rename',
      'load',
      'inviteParent',
      'removeParent',
    ]);
    expect(subject.message.value, isNull);
    expect(subject.busy.value, isFalse);
  });

  test(
    'a refused save is said in the backend\'s words, not swallowed',
    () async {
      final repo = FakeFamilyRepository(
        bundle: bundle(),
      )..renameFailWith = const PermissionFailure('Only the owner may rename.');
      final (subject, _) = build(repo);
      await subject.load();

      subject.familyName.text = 'Nope';
      await subject.save();

      expect(subject.message.value, 'Only the owner may rename.');
      expect(subject.busy.value, isFalse);
      expect(repo.calls.where((String c) => c == 'load').length, 1);
    },
  );

  test('a child opens on its own page, with its id', () async {
    final (subject, nav) = build(FakeFamilyRepository(bundle: bundle()));
    await subject.load();

    subject.goToChild('c1');

    expect(nav, [('push', AppRoutes.childProfile, 'c1')]);
  });

  test(
    'no family sends the parent to setup and does not stack a page',
    () async {
      final (subject, nav) = build(FakeFamilyRepository(bundle: null));
      await subject.load();

      subject.goToSetup();

      expect(nav, [('replace', AppRoutes.onboarding, null)]);
    },
  );
}
