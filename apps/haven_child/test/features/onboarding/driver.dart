import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import 'package:haven_child/core/device/device_information.dart';
import 'package:haven_child/core/device/fake_device_information.dart';
import 'package:haven_child/core/storage/onboarding_state_store.dart';
import 'package:haven_child/features/onboarding/controllers/onboarding_controller.dart';
import 'package:haven_child/features/onboarding/domain/onboarding_steps.dart';
import 'package:haven_child/features/onboarding/services/onboarding_completion.dart';
import 'package:haven_child/features/onboarding/views/pages/onboarding_page.dart';

import '../../support/fakes.dart';
import '../../support/host.dart';

/// How every onboarding widget test gets onto the five-step flow.
///
/// The controller is composed from documented seam fakes so a test can gate
/// the create, fail the draft store, or seed a resume — the page and every
/// step widget below it stay 100% real, pumped through the real theme.
final class OnboardingDriver {
  final List<String> pushed = <String>[];
  final List<String> finished = <String>[];
  late FakeOnboardingStateStore drafts;
  late FakeChildProfileRepository profiles;
  late FakeChildSessionStore sessions;
  late OnboardingController controller;

  /// The tester from the last [open] — so single-argument helpers like
  /// [type] can pump without every call site threading one.
  late WidgetTester tester;

  Future<OnboardingDriver> open(
    WidgetTester tester, {
    OnboardingDraft? seed,
    DeviceInformation? device,
    FakeOnboardingStateStore? store,
    FakeChildProfileRepository? repos,
    bool settle = true,
  }) async {
    pushed.clear();
    finished.clear();
    this.tester = tester;
    drafts = store ?? (FakeOnboardingStateStore()..draft = seed);
    profiles = repos ?? FakeChildProfileRepository();
    sessions = FakeChildSessionStore();
    controller = OnboardingController(
      drafts: drafts,
      completion: OnboardingCompletion(
        profiles: profiles,
        sessions: sessions,
        drafts: drafts,
        clock: FixedClock(DateTime.utc(2026, 11, 6, 9)),
      ),
      device: device ?? const FakeDeviceInformation(),
      push: pushed.add,
      finishRoute: finished.add,
    );
    Get.put<OnboardingController>(controller);
    await tester.pumpWidget(childHost(const OnboardingPage()));
    if (settle) await tester.pumpAndSettle();
    return this;
  }

  /// Jumps the visible step WITHOUT going through goNext — for tests that
  /// start mid-flow (review, permissions, finish). Persistence stays honest
  /// because the draft store already holds the seeded values.
  Future<void> showStep(WidgetTester tester, OnboardingStep step) async {
    controller.stepIndex.value = step.index;
    await tester.pumpAndSettle();
  }

  Future<void> type(String name) async {
    controller.nameController.text = name;
    await tester.pump();
  }

  Future<void> chooseChip(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(ChoiceChip, label));
    await tester.pump();
  }

  Future<void> continueOn(WidgetTester tester) => press(tester, 'Continue');
  Future<void> goBackButton(WidgetTester tester) => press(tester, 'Back');
  Future<void> retry(WidgetTester tester) => press(tester, 'Try again');

  bool chipSelected(String label) =>
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label)).selected;

  String get stepHeading => controller.currentStep.title;
  String get stepProgress => controller.currentStep.progressLabel;
}
