import 'package:haven_core/haven_core.dart';

import 'package:haven_child/core/device/fake_device_information.dart';
import 'package:haven_child/features/onboarding/controllers/onboarding_controller.dart';
import 'package:haven_child/features/onboarding/services/onboarding_completion.dart';

import '../../support/fakes.dart';

/// Shared harness for the two onboarding controller test files (the suite
/// exceeds the 200-line rule when combined). Every fake seam, the recorded
/// routes and the composition live here once.
final class ControllerHarness {
  final FakeOnboardingStateStore drafts = FakeOnboardingStateStore();
  final FakeChildProfileRepository profiles = FakeChildProfileRepository();
  final FakeChildSessionStore sessions = FakeChildSessionStore();
  final List<String> pushed = <String>[];
  final List<String> finished = <String>[];

  late OnboardingController subject;

  ControllerHarness() {
    rebuild();
  }

  /// Rebuilds the subject over the SAME seams — for tests that script a
  /// failure or a seed BEFORE the controller's async restore runs.
  void rebuild() {
    subject = OnboardingController(
      drafts: drafts,
      completion: OnboardingCompletion(
        profiles: profiles,
        sessions: sessions,
        drafts: drafts,
        clock: FixedClock(DateTime.utc(2026, 11, 6)),
      ),
      device: const FakeDeviceInformation(),
      push: pushed.add,
      finishRoute: finished.add,
    );
    // The parent-app shape: call the lifecycle method explicitly.
    subject.onInit();
  }

  /// Step 5 (finish) with a complete draft — the shape every `finish()`
  /// test starts from.
  void atFinishStep({
    String name = 'Ada',
    String bracket = '8-11',
    String avatar = 'rocket',
  }) {
    subject.stepIndex.value = 4;
    subject.nameController.text = name;
    subject.ageBracket.value = bracket;
    subject.avatar.value = avatar;
  }
}
