import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';
import 'zone_editor_page_driver.dart';

/// Removal is the one destructive write in this build, so it is tested apart
/// from the form: nothing is deleted until the parent has been asked twice, and
/// a refusal to delete is said out loud.
void main() {
  final ZoneEditorDriver driver = ZoneEditorDriver();

  tearDown(Get.reset);

  testWidgets('removal asks first, and a cancelled ask removes nothing', (
    tester,
  ) async {
    await driver.open(tester);

    await driver.press(
      tester,
      ZoneEditorDriver.removeLabel,
      buttonType: OutlinedButton,
    );

    expect(find.text('Remove this place?'), findsOneWidget);
    expect(find.textContaining('School go away'), findsOneWidget);

    await driver.press(tester, 'Cancel', buttonType: TextButton);

    expect(driver.repository.removedIds, isEmpty);
    expect(driver.closed, 0);
  });

  testWidgets('removal needs an explicit yes, then goes', (tester) async {
    await driver.open(tester);

    await driver.press(
      tester,
      ZoneEditorDriver.removeLabel,
      buttonType: OutlinedButton,
    );
    await driver.press(tester, ZoneEditorDriver.confirmLabel);

    expect(driver.repository.removedIds, ['z1']);
    expect(driver.closed, 1);
  });

  testWidgets('a refused removal is said, and the place stays on screen', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeSafeZonesRepository(found: zone('z1'))
        ..writeFailWith = const BackendFailure('fake: delete denied'),
    );

    await driver.press(
      tester,
      ZoneEditorDriver.removeLabel,
      buttonType: OutlinedButton,
    );
    await driver.press(tester, ZoneEditorDriver.confirmLabel);

    expect(find.text('fake: delete denied'), findsOneWidget);
    expect(driver.closed, 0);
  });
}
