import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/core/errors/captured_gaps.dart';
import 'package:haven_app/features/safe_zones/data/zones_repository.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';
import 'zones_page_driver.dart';

/// The list's promise: the places this family named, a real control for each one,
/// and the two boundaries stated in the captured words rather than paraphrased.
void main() {
  final SafeZonesDriver driver = SafeZonesDriver();

  tearDown(Get.reset);

  testWidgets('a refused read is the refusal, not an empty shelf', (
    tester,
  ) async {
    await driver.open(tester);

    expect(find.textContaining(SafeZonesDriver.readGap), findsOneWidget);
    expect(find.text(SafeZonesDriver.emptyLine), findsNothing);
  });

  testWidgets('a family with no named places says so plainly', (tester) async {
    await driver.open(tester, repo: FakeSafeZonesRepository(board: board()));

    expect(find.text(SafeZonesDriver.emptyLine), findsOneWidget);
  });

  testWidgets('a place shows its name, its width and whether it is in use', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeSafeZonesRepository(
        board: board(zones: [zone('z1', name: 'School', radiusM: 150)]),
      ),
    );

    expect(find.text('School'), findsOneWidget);
    expect(find.text('150 m across'), findsOneWidget);
    expect(find.text('In use'), findsOneWidget);
    expect(find.text('1 place named for this family.'), findsOneWidget);
  });

  testWidgets('a paused place is labelled paused, not hidden', (tester) async {
    await driver.open(
      tester,
      repo: FakeSafeZonesRepository(
        board: board(zones: [zone('z1', active: false)]),
      ),
    );

    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('In use'), findsNothing);
  });

  testWidgets('every place carries a working edit control', (tester) async {
    await driver.open(
      tester,
      repo: FakeSafeZonesRepository(
        board: board(
          zones: [
            zone('z1'),
            zone('z2', name: 'Grandma\'s'),
          ],
        ),
      ),
    );

    expect(find.text(SafeZonesDriver.edit), findsNWidgets(2));
    await driver.press(
      tester,
      SafeZonesDriver.edit,
      buttonType: OutlinedButton,
    );

    expect(driver.routes, [('push', AppRoutes.safeZoneEditor, 'z1')]);
  });

  testWidgets('the create boundary is the captured sentence, word for word', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeSafeZonesRepository(board: board(zones: [zone('z1')])),
    );

    expect(
      find.textContaining(HavenSafeZonesRepository.createMissing),
      findsOneWidget,
    );
    expect(
      find.text('Haven cannot name a new place in this build yet.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'no add control is offered for a write that can only be refused',
    (tester) async {
      await driver.open(
        tester,
        repo: FakeSafeZonesRepository(board: board(zones: [zone('z1')])),
      );

      for (final String label in [
        'Add a place',
        'New place',
        'Name a place',
        'Create',
      ]) {
        expect(find.text(label), findsNothing);
      }
      expect(
        find.text(
          'No place is named for this family yet. A device cannot be told '
          'when it has arrived somewhere Haven does not know about.',
        ),
        findsNothing,
      );
    },
  );

  testWidgets('the presence boundary is stated, not worked around', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeSafeZonesRepository(board: board(zones: [zone('z1')])),
    );

    expect(
      find.textContaining(CapturedGaps.presenceLaneMissing),
      findsOneWidget,
    );
    expect(find.textContaining('inside a safe place'), findsOneWidget);
  });

  testWidgets('the page says how a place is moved before it is opened', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeSafeZonesRepository(board: board(zones: [zone('z1')])),
    );

    expect(find.text('What you can change about a place'), findsOneWidget);
    expect(find.textContaining('no map to tap a point on'), findsOneWidget);
  });

  testWidgets('no family routes to setup and replaces the stack', (
    tester,
  ) async {
    await driver.open(tester, repo: FakeSafeZonesRepository(noFamily: true));

    expect(find.text('Haven is not set up yet'), findsOneWidget);
    await driver.press(tester, 'Start setup');
    expect(driver.routes, [('replace', AppRoutes.onboarding, null)]);
  });

  testWidgets('a retryable failure offers a retry and re-reads', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeSafeZonesRepository(
        readFailWith: const NetworkFailure('Could not reach the backend.'),
      ),
    );

    expect(find.text('Could not reach the backend.'), findsOneWidget);
    await driver.press(tester, 'Try again');
    expect(driver.repository.loadCount, 2);
  });

  testWidgets('the limits card is not shown next to a refusal', (tester) async {
    await driver.open(tester);

    expect(find.text('What you can change about a place'), findsNothing);
  });
}
