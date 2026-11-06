import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import 'package:haven_child/core/storage/onboarding_state_store.dart';
import 'package:haven_child/features/onboarding/controllers/onboarding_controller.dart';
import 'package:haven_child/features/onboarding/domain/onboarding_steps.dart';

import '../../support/fakes.dart';
import '../../support/host.dart';
import 'driver.dart';

/// Brief §7 widget coverage: welcome screen, setup validation errors,
/// avatar-to-draft persistence, loading/error/empty states with retry.
void main() {
  final driver = OnboardingDriver();

  tearDown(() => Get.reset());

  testWidgets('step 1 introduces the app with its honest limits', (tester) async {
    await driver.open(tester);
    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Hi! Let’s set up Haven on this device.'), findsOneWidget);
    // The two promises the brief pins verbatim.
    expect(
      find.text('Parent connection: Not connected'),
      findsOneWidget,
    );
    expect(find.textContaining('Nothing is monitored yet'), findsOneWidget);
    // Back cannot leave the flow; the welcome step still offers Continue.
    expect(
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Back')).onPressed,
      isNull,
    );
  });

  testWidgets('Continue walks the steps in order with progress copy', (tester) async {
    await driver.open(tester);
    await driver.continueOn(tester);
    expect(find.text('Step 2 of 5'), findsOneWidget);
    expect(find.text('About you'), findsOneWidget);
    expect(driver.drafts.saved.last.stepIndex, 1); // the resume point moved too
  });

  testWidgets('an empty name is refused at the gate, visibly', (tester) async {
    await driver.open(tester);
    await driver.continueOn(tester); // welcome -> About you
    await driver.continueOn(tester); // empty name
    expect(find.text('Enter a name.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(controllerStep(tester), OnboardingStep.childProfile); // did not advance
  });

  testWidgets('a valid name without an age bracket hits the second gate', (
    tester,
  ) async {
    await driver.open(tester);
    await driver.continueOn(tester);
    await driver.type('Ada');
    await driver.continueOn(tester);
    expect(find.text('Pick your age group.'), findsOneWidget);

    // Retry re-reads the persisted draft (nothing was typed there yet), so
    // the form comes back blank — the documented restore behaviour.
    await driver.retry(tester);
    // InputDecorator keeps the hint Text in the tree even when it is not
    // painted, so assert on the field itself, not on a bare label count.
    expect(find.widgetWithText(TextField, 'Your first name'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty, // the unsaved 'Ada' was dropped by the draft restore
    );
  });

  testWidgets('name + bracket + avatar walk through and persist to the draft', (
    tester,
  ) async {
    await driver.open(tester);
    await driver.continueOn(tester);
    await driver.type('Ada');
    await driver.chooseChip(tester, '8-11 yrs');
    await driver.chooseChip(tester, 'rocket');
    expect(driver.chipSelected('8-11 yrs'), isTrue);
    expect(driver.chipSelected('rocket'), isTrue);
    await driver.continueOn(tester);

    expect(find.text('This device'), findsOneWidget);
    final saved = driver.drafts.saved.last;
    expect(saved.displayName, 'Ada');
    expect(saved.ageBracket, '8-11');
    expect(saved.avatar, 'rocket'); // the §7 "avatar selection persists" proof
  });

  testWidgets('a pending draft store shows the spinner, not an empty form', (
    tester,
  ) async {
    final store = FakeOnboardingStateStore()
      ..readGate = Completer<void>();
    await driver.open(tester, store: store, settle: false);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    store.readGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('a failing draft store is an error with a working retry', (tester) async {
    final store = FakeOnboardingStateStore()
      ..readFailure = const StorageFailure('The draft could not be read.');
    await driver.open(tester, store: store);
    expect(find.text('The draft could not be read.'), findsOneWidget);

    store.readFailure = null;
    await driver.retry(tester);
    expect(find.text('Welcome'), findsOneWidget);
    expect(store.readCount, greaterThanOrEqualTo(2));
  });

  testWidgets('device review summarises facts and pushes the full screen', (
    tester,
  ) async {
    await driver.open(tester, seed: const OnboardingDraft(stepIndex: 2));
    expect(find.text('Model'), findsOneWidget);
    expect(find.text('Unavailable'), findsWidgets);
    await press(tester, 'Open device details');
    expect(driver.pushed, ['/device']);
  });

  testWidgets('the permissions step explains all four and requests nothing', (
    tester,
  ) async {
    await driver.open(tester, seed: const OnboardingDraft(stepIndex: 3));
    expect(find.text('No permission has been requested.'), findsOneWidget);
    for (final label in [
      'Screen time access',
      'Location',
      'Notifications',
      'Runs in the background',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    await press(tester, 'See the permission dashboard');
    expect(driver.pushed, ['/permissions']);
  });

  testWidgets('Back walks down and cannot pass step 1', (tester) async {
    await driver.open(tester, seed: const OnboardingDraft(stepIndex: 2));
    await driver.goBackButton(tester);
    expect(driver.stepProgress, 'Step 2 of 5');
    await driver.goBackButton(tester);
    expect(driver.stepProgress, 'Step 1 of 5');
    // Back is disabled on welcome, so no third persist happens.
    final before = driver.drafts.saved.length;
    await driver.goBackButton(tester);
    expect(driver.drafts.saved.length, before);
  });

  testWidgets('the About-you step fits a 320x568 screen', (tester) async {
    await driver.open(tester, seed: const OnboardingDraft(stepIndex: 1));
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();
    expect(find.text('About you'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

OnboardingStep controllerStep(WidgetTester tester) =>
    Get.find<OnboardingController>().currentStep;
