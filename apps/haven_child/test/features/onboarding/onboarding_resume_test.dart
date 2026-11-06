import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:haven_child/core/storage/onboarding_state_store.dart';

import '../../support/fakes.dart';
import 'driver.dart';

/// Brief §7 "resume after restart (relaunch pump → lands on saved step with
/// draft values)": one fake store plays "the device", and each "restart" is
/// a fresh controller — exactly what `restore()` sees after a process death.
void main() {
  final driver = OnboardingDriver();
  tearDown(() => Get.reset());

  testWidgets('a killed app reopens on the saved step with every draft value', (
    tester,
  ) async {
    // Session one: two steps in, with a half-filled profile.
    final store = FakeOnboardingStateStore();
    await driver.open(tester, store: store);
    await driver.continueOn(tester);
    await driver.type('Ada');
    await driver.chooseChip(tester, '12-14 yrs');
    await driver.chooseChip(tester, 'panda');
    await driver.continueOn(tester); // saves {step 2, Ada, 12-14, panda}
    expect(store.draft!.stepIndex, 2);
    Get.reset(); // process death: controllers gone, the store survives

    // Session two: a brand-new controller over the same store.
    await driver.open(tester, store: store);
    expect(find.text('Step 3 of 5'), findsOneWidget);
    expect(find.text('This device'), findsOneWidget);
    expect(driver.controller.nameController.text, 'Ada');
    expect(driver.controller.ageBracket.value, '12-14');
    expect(driver.controller.avatar.value, 'panda');
  });

  testWidgets('a restart on the About-you step shows the stored fields in the UI', (
    tester,
  ) async {
    await driver.open(
      tester,
      seed: const OnboardingDraft(
        stepIndex: 1,
        displayName: 'Ada',
        ageBracket: '4-7',
        avatar: 'bike',
      ),
    );
    // InputDecorator keeps the hint node in the tree even with text filled
    // in, so the field-scoped finder is the honest "the form is on screen"
    // assertion; the prefill itself is proven below on the real controller.
    expect(find.widgetWithText(TextField, 'Your first name'), findsOneWidget);
    // The draft value is in the REAL field, not just the controller.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Ada',
    );
    expect(driver.chipSelected('4-7 yrs'), isTrue);
    expect(driver.chipSelected('bike'), isTrue);
  });

  testWidgets('a step index from a future build clamps into a real step', (
    tester,
  ) async {
    await driver.open(tester, seed: const OnboardingDraft(stepIndex: 87));
    expect(find.text('Step 5 of 5'), findsOneWidget);
    expect(find.text('All set'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('negative indices clamp back to the welcome step', (tester) async {
    await driver.open(tester, seed: const OnboardingDraft(stepIndex: -4));
    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('continuing after a restart does not re-save the old step', (
    tester,
  ) async {
    final store = FakeOnboardingStateStore()
      ..draft = const OnboardingDraft(stepIndex: 3, displayName: 'Ada');
    await driver.open(tester, store: store);
    expect(find.text('Permissions'), findsOneWidget);
    await driver.continueOn(tester);
    expect(store.draft!.stepIndex, 4);
    expect(driver.drafts.saved.length, 1); // one write for this session only
  });
}
