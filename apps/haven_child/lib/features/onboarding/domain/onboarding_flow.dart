import 'package:haven_core/haven_core.dart';

import 'onboarding_steps.dart';

/// The onboarding state machine, pure and side-effect free: which step may
/// advance, and why not. The controller owns persistence; this owns the rules,
/// so Agent 3 can test every transition without a widget or a filesystem.
abstract final class OnboardingFlow {
  /// Returns a user-facing blocker for [step], or null when it may advance.
  ///
  /// The name rule is the app's one real validator — haven_core's
  /// `validateDisplayName` (the `profiles.display_name` check constraint);
  /// the age bracket is required because every later screen keys off it.
  static String? blockerFor(
    OnboardingStep step, {
    required String displayName,
    required String ageBracket,
  }) {
    switch (step) {
      case OnboardingStep.welcome:
        return null;
      case OnboardingStep.childProfile:
        final nameProblem = validateDisplayName(displayName);
        if (nameProblem != null) return nameProblem;
        if (ageBracket.trim().isEmpty) return 'Pick your age group.';
        return null;
      case OnboardingStep.deviceReview:
      case OnboardingStep.permissionsIntro:
      case OnboardingStep.finish:
        // Information steps: nothing to validate, nothing to request.
        return null;
    }
  }

  /// Whether the profile data is complete enough to create the row at the
  /// end. The finish action re-checks even when step 2 was never visited in
  /// this session (a resumed draft may be incomplete).
  static String? profileProblem({
    required String displayName,
    required String ageBracket,
  }) => blockerFor(
    OnboardingStep.childProfile,
    displayName: displayName,
    ageBracket: ageBracket,
  );

  static int clampIndex(int index) => index.clamp(0, OnboardingStep.count - 1);
}
