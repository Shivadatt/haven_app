import 'package:flutter_test/flutter_test.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/family/controllers/child_profile_controller.dart';
import 'package:haven_app/features/family/data/family_models.dart';

import 'fakes.dart';

void main() {
  final FamilyBundle twoChildren = FamilyBundle(
    family: const Family(
      id: 'f1',
      name: 'Rivera',
      ownerId: 'u1',
      settings: <String, Object?>{},
    ),
    parents: const [
      FamilyPerson(
        member: FamilyMember(
          id: 'm1',
          familyId: 'f1',
          userId: 'u1',
          role: 'parent',
          status: 'active',
        ),
        profile: Profile(id: 'u1', role: 'parent', displayName: 'Rae'),
      ),
    ],
    children: [child('c1', 'Ivy'), child('c2', 'Kai')],
  );

  (ChildProfileController, List<String>) build(
    String childUserId,
    FakeFamilyRepository repo,
  ) {
    final nav = <String>[];
    final subject = ChildProfileController(
      childUserId: childUserId,
      repository: repo,
      goTo: (String route, Object? _) => nav.add(route),
    );
    return (subject, nav);
  }

  test('shows the one child this page was opened for', () async {
    final (subject, _) = build('c2', FakeFamilyRepository(bundle: twoChildren));

    await subject.load();

    expect(subject.isLoading.value, isFalse);
    expect(subject.person.value!.valueOrNull!.name, 'Kai');
  });

  test(
    'a child who is not in the family is an empty state, not a guess',
    () async {
      final (subject, _) = build(
        'c9',
        FakeFamilyRepository(bundle: twoChildren),
      );

      await subject.load();

      expect(subject.person.value!.isOk, isTrue);
      expect(subject.person.value!.valueOrNull, isNull);
    },
  );

  test(
    'the device half of the page is the F6 refusal, read not typed',
    () async {
      final (subject, _) = build(
        'c1',
        FakeFamilyRepository(bundle: twoChildren),
      );

      await subject.load();

      final BlockedFailure gap = subject.deviceGap.value!;
      expect(gap.missing, contains('docs/stage1/00-status-register.md:86'));
      expect(gap.message, contains("this child's"));
    },
  );

  test('a failed family read is kept as a failure', () async {
    final (subject, _) = build(
      'c1',
      FakeFamilyRepository()
        ..loadFailWith = const NetworkFailure('No connection.'),
    );

    await subject.load();

    expect(subject.person.value!.failureOrNull, isA<NetworkFailure>());
  });

  test('the removal refusal is read, and carries this child', () async {
    final repo = FakeFamilyRepository(bundle: twoChildren);
    final (subject, _) = build('c1', repo);

    await subject.load();

    expect(repo.lastChildUserId, 'c1');
    expect(repo.calls, contains('unlinkChild'));
    expect(subject.removalGap.value!.missing, contains('removing a child'));
  });

  test('the refusals do not blank the child the page is about', () async {
    final repo = FakeFamilyRepository(bundle: twoChildren);
    final (subject, _) = build('c1', repo);

    await subject.load();

    expect(subject.person.value!.valueOrNull!.name, 'Ivy');
    expect(subject.deviceGap.value, isNotNull);
    expect(subject.removalGap.value, isNotNull);
  });

  test('back to family is a route, not a dead button', () async {
    final (subject, nav) = build('c9', FakeFamilyRepository(bundle: null));
    await subject.load();

    subject.goToFamily();

    expect(nav, [AppRoutes.family]);
  });
}
