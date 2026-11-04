import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/family/data/family_models.dart';
import 'package:haven_core/haven_core.dart';

import '../support/data_fakes.dart';
import '../support/fakes.dart';
import 'repository_harness.dart';

void main() {
  test('reads the family and splits its members by role', () async {
    final subject = Harness(
      tables: fullTables(
        members: [memberRow('u2', 'parent'), memberRow('c1', 'child')],
        profiles: [profileRow('u2', 'Sam'), profileRow('c1', 'Ivy')],
      ),
    ).subject;

    final FamilyBundle? bundle = (await subject.load()).valueOrNull;

    expect(bundle?.family.name, 'Rivera');
    expect(bundle?.parents.map((FamilyPerson p) => p.name), ['Rae', 'Sam']);
    expect(bundle?.children.map((FamilyPerson p) => p.name), ['Ivy']);
  });

  test('a member with no profile row is still listed', () async {
    final subject = Harness(
      tables: fullTables(members: [memberRow('c1', 'child')]),
    ).subject;

    final FamilyBundle? bundle = (await subject.load()).valueOrNull;
    final FamilyPerson child = bundle!.children.single;

    expect(child.hasProfile, isFalse);
    // Hiding a child from their own family would be worse than a placeholder.
    expect(child.name, 'A child');
  });

  test('a removed member is not shown', () async {
    final subject = Harness(
      tables: fullTables(
        members: [
          memberRow('c1', 'child'),
          memberRow('c2', 'child', status: 'removed'),
        ],
      ),
    ).subject;

    final FamilyBundle? bundle = (await subject.load()).valueOrNull;

    expect(bundle?.children.map((FamilyPerson p) => p.userId), ['c1']);
  });

  test('no membership row is the first-run state, not a failure', () async {
    final subject = Harness(tables: noFamilyTables()).subject;

    final Result<FamilyBundle?> result = await subject.load();

    expect(result.isOk, isTrue);
    expect(result.valueOrNull, isNull);
  });

  test('no session comes back as a sign-in problem', () async {
    final subject = Harness(withAuth: FakeUserAuth(null)).subject;

    final HavenFailure failure = (await subject.load()).failureOrNull!;

    expect(failure, isA<AuthFailure>());
    expect((failure as AuthFailure).signedOut, isTrue);
  });

  test('a failed profile read is not shown as an empty family', () async {
    final subject = Harness(
      withRows: FakeRowReader(fullTables(members: [memberRow('c1', 'child')]), {
        TableName.profiles: const NetworkFailure('Could not read.'),
      }),
    ).subject;

    final Result<FamilyBundle?> result = await subject.load();

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  group('the abilities with no approved contract', () {
    test('adding a parent names what is missing', () async {
      final subject = Harness().subject;

      final BlockedFailure failure =
          (await subject.inviteParent()).failureOrNull! as BlockedFailure;

      expect(failure.missing, contains('family_members'));
      expect(failure.message, 'Haven cannot add another parent yet.');
    });

    test('removing a parent names what is missing', () async {
      final subject = Harness().subject;

      final BlockedFailure failure =
          (await subject.removeParent()).failureOrNull! as BlockedFailure;

      expect(failure.missing, contains('unlink_child'));
      expect(failure.message, 'Haven cannot remove another parent yet.');
    });
  });
}
