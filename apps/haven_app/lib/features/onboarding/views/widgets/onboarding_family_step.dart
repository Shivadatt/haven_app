import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/onboarding_controller.dart';

/// Step 2: Family creation.
final class OnboardingFamilyStep extends GetView<OnboardingController> {
  const OnboardingFamilyStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Name your family', style: HavenText.headline),
        const SizedBox(height: HavenSpacing.sm),
        Text(
          'This is the group that holds your children and their devices. '
          'You can change nothing about it later except its name.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HavenField(
                label: 'Family name',
                controller: controller.familyName,
                maxLength: 80,
                helper: 'Up to 80 characters.',
                enabled: !controller.isBusy,
              ),
              const SizedBox(height: HavenSpacing.md),
              if (controller.message.value != null) ...[
                Text(controller.message.value!, style: HavenText.body),
                const SizedBox(height: HavenSpacing.sm),
              ],
              HavenButton(
                label: 'Create my family',
                expand: true,
                busy: controller.isBusy,
                onPressed: controller.submitFamily,
              ),
            ],
          ),
        ),
        const SizedBox(height: HavenSpacing.md),
        Text(
          'Adding a child and pairing a device comes next.',
          style: HavenText.caption,
        ),
      ],
    );
  }
}
