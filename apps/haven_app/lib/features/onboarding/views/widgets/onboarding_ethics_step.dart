import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/onboarding_controller.dart';

/// Step 1: Ethics and monitoring disclosure.
final class OnboardingEthicsStep extends GetView<OnboardingController> {
  const OnboardingEthicsStep({super.key});

  static const _points = [
    'Which apps are installed on your child’s Android device, and how long '
        'each one is used that day.',
    'Whether the device is online, and its last known location — but only '
        'while your child’s Haven app is open on it.',
    'Time limits and app blocks you choose. Haven reports them back only once '
        'the device confirms they took effect.',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What Haven watches', style: HavenText.headline),
        const SizedBox(height: HavenSpacing.sm),
        Text(
          'Your child sees Haven on their device and what it is for. '
          'Haven does not hide itself, and it does not bypass Android’s '
          'permissions.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        for (final String point in _points) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(child: Text(point, style: HavenText.body)),
            ],
          ),
          const SizedBox(height: HavenSpacing.sm),
        ],
        const BlockedNotice(
          requirement:
              'Haven cannot store a record that you agreed to this yet.',
          missing:
              'no consent table or consent column in the captured schema '
              '(docs/stage1/evidence/schema-columns.md:293). Consent is saved locally in preferences.',
        ),
        const SizedBox(height: HavenSpacing.lg),
        InkWell(
          onTap: () => controller.acknowledged.toggle(),
          child: Row(
            children: [
              Obx(
                () => Checkbox(
                  value: controller.acknowledged.value,
                  onChanged: (_) => controller.acknowledged.toggle(),
                ),
              ),
              Expanded(
                child: Text(
                  'I have read what Haven watches and I am the parent or guardian '
                  'responsible for this child.',
                  style: HavenText.body,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: HavenSpacing.md),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.message.value != null) ...[
                Text(controller.message.value!, style: HavenText.body),
                const SizedBox(height: HavenSpacing.sm),
              ],
              HavenButton(
                label: 'I understand — continue',
                expand: true,
                onPressed: controller.continueFromExplain,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
