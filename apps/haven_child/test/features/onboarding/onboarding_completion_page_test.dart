import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'package:haven_child/core/storage/onboarding_state_store.dart';

import '../../support/fakes.dart';
import '../../support/host.dart';
import 'driver.dart';

/// The one write of the flow, guarded at widget level exactly as the brief
/// promises: one create, a dead double tap, honest busy copy, and navigation
/// to the profile — nothing softer.
void main() {
  final driver = OnboardingDriver();
  tearDown(() => Get.reset());

  const finishedDraft = OnboardingDraft(
    stepIndex: 4,
    displayName: 'Ada',
    ageBracket: '8-11',
    avatar: 'star',
  );

  testWidgets('the finish step previews the draft and says it happens once', (
    tester,
  ) async {
    await driver.open(tester, seed: finishedDraft);
    expect(find.text('Step 5 of 5'), findsOneWidget);
    expect(find.text('Ada'), findsWidgets);
    expect(find.text('Age group'), findsOneWidget);
    expect(find.text('8-11'), findsWidgets);
    expect(find.textContaining('It happens once'), findsOneWidget);
    expect(find.text('Parent connection: Not connected'), findsOneWidget);
  });

  testWidgets('submit creates once, clears the draft and routes to /profile', (
    tester,
  ) async {
    await driver.open(tester, seed: finishedDraft);
    await press(tester, 'Create my profile');

    expect(driver.profiles.createCount, 1);
    expect(driver.profiles.lastCreateName, 'Ada');
    expect(driver.sessions.session!.profileId, 'p1');
    expect(driver.drafts.draft, isNull); // resume point consumed on success
    expect(driver.finished, ['/profile']);
  });

  testWidgets('a fast double tap cannot start a second create', (tester) async {
    final gate = Completer<void>();
    final repo = FakeChildProfileRepository()..createGate = gate;
    await driver.open(tester, seed: finishedDraft, repos: repo);

    await tester.tap(find.text('Create my profile'));
    await tester.pump(); // one frame: the busy state renders

    // In flight: the button is deliberately disabled with busy copy, so the
    // second physical tap hits nothing, and finish()'s flag is layer two.
    expect(find.text('Creating…'), findsOneWidget);
    await tester.tap(find.text('Creating…'));
    await tester.pump();
    expect(repo.createCount, 0); // still waiting on the gate

    gate.complete();
    await tester.pumpAndSettle();
    expect(repo.createCount, 1);
    expect(driver.finished, ['/profile']);
  });

  testWidgets('a create-once refusal is shown, never swallowed', (tester) async {
    final repo = FakeChildProfileRepository()
      ..createFailure = const ValidationFailure(
        'A child profile already exists on this device, so nothing was created.',
        detail: 'child_profile_create_once',
      );
    await driver.open(tester, seed: finishedDraft, repos: repo);
    await press(tester, 'Create my profile');
    expect(find.textContaining('already exists on this device'), findsOneWidget);
    expect(driver.finished, isEmpty);
  });

  testWidgets('an incomplete resumed draft bounces back to step 2 first', (
    tester,
  ) async {
    await driver.open(
      tester,
      seed: const OnboardingDraft(stepIndex: 4, displayName: 'Ada'),
    );
    await press(tester, 'Create my profile');
    expect(driver.stepProgress, 'Step 2 of 5');
    expect(find.textContaining('Back to the "About you" step'), findsOneWidget);
    expect(driver.profiles.createCount, 0);
  });

  testWidgets('a half-finished device finishes WITHOUT touching the profile', (
    tester,
  ) async {
    // Profile exists (create-once would refuse); completion must complete
    // the session instead — the repository-level promise, widget-level path.
    final repo = FakeChildProfileRepository()
      ..profile = Profile(
        id: 'first-ever',
        role: ProfileRole.child.wire,
        displayName: 'Ada',
      );
    await driver.open(tester, seed: finishedDraft, repos: repo);
    await press(tester, 'Create my profile');
    expect(repo.createCount, 0);
    expect(driver.sessions.session!.profileId, 'first-ever');
    expect(driver.finished, ['/profile']);
  });

  testWidgets('the finish step survives a 320x568 phone', (tester) async {
    await driver.open(tester, seed: finishedDraft);
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();
    expect(find.text('All set'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
