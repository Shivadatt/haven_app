import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../controllers/onboarding_controller.dart';
import '../widgets/onboarding_child_step.dart';
import '../widgets/onboarding_device_step.dart';
import '../widgets/onboarding_ethics_step.dart';
import '../widgets/onboarding_family_step.dart';
import '../widgets/onboarding_step_indicator.dart';

/// Progressive multi-step onboarding wizard for Haven parents.
final class OnboardingPage extends GetView<OnboardingController> {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Setting up Haven',
      showBack: false,
      body: HavenPageBody(
        child: Obx(
          () => ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
            children: [
              OnboardingStepIndicator(current: controller.step.value),
              switch (controller.step.value) {
                OnboardingStep.explain => const OnboardingEthicsStep(),
                OnboardingStep.setup => const OnboardingFamilyStep(),
                OnboardingStep.child => const OnboardingChildStep(),
                OnboardingStep.device => const OnboardingDeviceStep(),
              },
            ],
          ),
        ),
      ),
    );
  }
}
