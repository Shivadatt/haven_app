import 'package:flutter_test/flutter_test.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_app/features/family/data/family_scope.dart';

import '../support/fakes.dart';
import 'repository_harness.dart';

/// The one place that decides which family a caller may act on. The id is read
/// from the caller's own membership row and never taken from the screen.
void main() {
  test('takes the family id from my own membership row', () async {
    final harness = Harness();

    final FamilyScope scope = (await harness.scope.resolve()).valueOrNull!;

    expect(scope.familyId, familyId);
    expect(scope.session.userId, 'u1');
  });

  test('says "not set up yet" in a form a screen can route on', () async {
    final harness = Harness(tables: noFamilyTables());

    final HavenFailure failure = (await harness.scope.resolve()).failureOrNull!;

    expect(FamilyScopeReader.isMissingFamily(failure), isTrue);
    expect(failure, isA<ValidationFailure>());
    expect((failure as ValidationFailure).field, 'family');
  });

  test('a read that failed is not reported as "no family yet"', () async {
    final harness = Harness();
    harness.rows.failWith = const NetworkFailure('No connection.');

    final HavenFailure failure = (await harness.scope.resolve()).failureOrNull!;

    expect(FamilyScopeReader.isMissingFamily(failure), isFalse);
    expect(failure, isA<NetworkFailure>());
  });

  test('with no session there is nothing to resolve', () async {
    final harness = Harness(withAuth: FakeUserAuth(null));

    final HavenFailure failure = (await harness.scope.resolve()).failureOrNull!;

    expect(failure, isA<AuthFailure>());
    expect(FamilyScopeReader.isMissingFamily(failure), isFalse);
  });
}
