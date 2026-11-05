import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/onboarding_controller.dart';

/// Step 4: Device setup walkthrough and celebratory completion.
final class OnboardingDeviceStep extends GetView<OnboardingController> {
  const OnboardingDeviceStep({super.key});

  static const _walkthrough = [
    'Install Haven on your child’s Android phone or tablet.',
    'Open Haven on their device and tap "Connect to Family" using your family code.',
    'Grant requested Android permissions so safe limits and app blocking can take effect.',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Device setup', style: HavenText.headline),
        const SizedBox(height: HavenSpacing.sm),
        Text(
          'Connect your child’s device in three quick steps:',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        for (int i = 0; i < _walkthrough.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${i + 1}. ', style: HavenText.body),
              Expanded(child: Text(_walkthrough[i], style: HavenText.body)),
            ],
          ),
          const SizedBox(height: HavenSpacing.sm),
        ],
        const SizedBox(height: HavenSpacing.md),
        const SectionCard(
          title: '🎉 Setup complete!',
          subtitle: 'Your family is protected with Haven.',
          child: Text(
            'Your family and child profile are saved. You can now finish onboarding '
            'and head straight to your family dashboard.',
            style: HavenText.body,
          ),
        ),
        const SizedBox(height: HavenSpacing.lg),
        HavenButton(
          label: 'Finish setup',
          expand: true,
          busy: controller.isBusy,
          onPressed: controller.completeOnboarding,
        ),
      ],
    );
  }
}
