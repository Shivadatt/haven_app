import 'package:flutter/material.dart';
import '../../../../app/theme/haven_colors.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../data/onboarding_models.dart';

/// Progress header indicating the current step (1 through 4) in onboarding.
final class OnboardingStepIndicator extends StatelessWidget {
  const OnboardingStepIndicator({required this.current, super.key});

  final OnboardingStep current;

  int get _stepIndex => switch (current) {
    OnboardingStep.explain => 1,
    OnboardingStep.setup => 2,
    OnboardingStep.child => 3,
    OnboardingStep.device => 4,
  };

  String get _stepLabel => switch (current) {
    OnboardingStep.explain => 'Step 1 of 4: Ethics & Consent',
    OnboardingStep.setup => 'Step 2 of 4: Family Setup',
    OnboardingStep.child => 'Step 3 of 4: Add Child',
    OnboardingStep.device => 'Step 4 of 4: Device Connection',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HavenSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_stepLabel, style: HavenText.caption),
          const SizedBox(height: HavenSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _stepIndex / 4.0,
              minHeight: 6,
              backgroundColor: HavenColors.outline,
              valueColor: const AlwaysStoppedAnimation<Color>(HavenColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
