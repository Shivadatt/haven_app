import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/errors/captured_gaps.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';
import 'zone_editor_page_driver.dart';

/// The editor's promise: it opens on the row, refuses a value the database would
/// refuse, sends only what changed, and will not remove a place until the parent
/// says so twice.
void main() {
  final ZoneEditorDriver driver = ZoneEditorDriver();

  tearDown(Get.reset);

  testWidgets(
    'a place this account cannot read is a refusal, not a blank form',
    (tester) async {
      await driver.open(tester, repo: FakeSafeZonesRepository());

      expect(find.textContaining(ZoneEditorDriver.readGap), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text(ZoneEditorDriver.saveLabel), findsNothing);
    },
  );

  testWidgets('an editor opened with no place named offers no form', (
    tester,
  ) async {
    await driver.open(tester, zoneId: '', repo: FakeSafeZonesRepository());

    expect(find.byType(TextFormField), findsNothing);
    expect(find.text(ZoneEditorDriver.saveLabel), findsNothing);
    expect(find.text(ZoneEditorDriver.removeLabel), findsNothing);
    // The id asked for is the id the data layer was given — the screen does not
    // fill in a place the parent never chose.
    expect(driver.repository.readIds.single, '');
  });

  testWidgets('the form opens on what the row says', (tester) async {
    await driver.open(tester);

    expect(
      find.widgetWithText(TextFormField, 'What to call it'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'Latitude'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Longitude'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'How wide, in metres'),
      findsOneWidget,
    );
    expect(find.text('School'), findsOneWidget);
    expect(
      find.textContaining('Named for this family since 5/1/2026'),
      findsOneWidget,
    );
  });

  testWidgets('nothing to save until something changed', (tester) async {
    await driver.open(tester);

    expect(driver.saveEnabled(tester), isFalse);

    await driver.type(tester, 'What to call it', 'Grandma\'s');
    expect(driver.saveEnabled(tester), isTrue);
  });

  testWidgets('a width the database would refuse is said before saving', (
    tester,
  ) async {
    await driver.open(tester);

    await driver.type(tester, 'How wide, in metres', '10');

    expect(find.textContaining('between 50 and 5000 metres'), findsOneWidget);
    expect(driver.saveEnabled(tester), isFalse);
  });

  testWidgets(
    'a latitude outside the hemisphere is refused where it is typed',
    (tester) async {
      await driver.open(tester);

      await driver.type(tester, 'Latitude', '91');

      expect(
        find.text(
          'That is not a valid latitude: it has to be between -90 and 90.',
        ),
        findsOneWidget,
      );
      expect(driver.saveEnabled(tester), isFalse);
    },
  );

  testWidgets('a name emptied is refused, not silently trimmed away', (
    tester,
  ) async {
    await driver.open(tester);

    await driver.type(tester, 'What to call it', '   ');

    expect(find.textContaining('needs a name'), findsOneWidget);
  });

  testWidgets('saving sends this place and closes the screen', (tester) async {
    await driver.open(tester);

    await driver.type(tester, 'What to call it', 'Grandma\'s');
    await driver.press(tester, ZoneEditorDriver.saveLabel);

    expect(driver.repository.savedIds, ['z1']);
    expect(driver.repository.lastSaved!.name, 'Grandma\'s');
    expect(driver.closed, 1);
  });

  testWidgets('a refused save keeps the parent on the form, with the reason', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeSafeZonesRepository(found: zone('z1'))
        ..writeFailWith = const PermissionFailure('fake: write denied'),
    );

    await driver.type(tester, 'What to call it', 'Grandma\'s');
    await driver.press(tester, ZoneEditorDriver.saveLabel);

    expect(find.text('fake: write denied'), findsOneWidget);
    expect(driver.closed, 0);
  });

  testWidgets('pausing a place is a change the parent can save', (
    tester,
  ) async {
    await driver.open(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('A paused place is not evaluated.'), findsOneWidget);
    expect(driver.saveEnabled(tester), isTrue);

    await driver.press(tester, ZoneEditorDriver.saveLabel);
    expect(driver.repository.lastSaved!.active, isFalse);
  });

  testWidgets('the editor never offers to name a new place', (tester) async {
    await driver.open(tester);

    for (final String label in ['Add a place', 'New place', 'Save as new']) {
      expect(find.text(label), findsNothing);
    }
    // The editor is about this row, so the create and presence boundaries belong
    // to the list — repeating them here would crowd the form that has the only
    // working write in the app.
    expect(find.textContaining(CapturedGaps.presenceLaneMissing), findsNothing);
  });
}
