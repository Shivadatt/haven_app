import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/onboarding_controller.dart';

/// What Haven watches, in the parent's language, before anything is set up —
/// and an explicit acknowledgement, because setup starts here.
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
            children: controller.step.value == OnboardingStep.explain
                ? const [_ExplainStep()]
                : const [_SetupStep()],
          ),
        ),
      ),
    );
  }
}

class _ExplainStep extends GetView<OnboardingController> {
  const _ExplainStep();

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
              '(docs/stage1/evidence/schema-columns.md:293)',
        ),
        const SizedBox(height: HavenSpacing.lg),
        _AcknowledgeRow(),
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

class _AcknowledgeRow extends GetView<OnboardingController> {
  @override
  Widget build(BuildContext context) => InkWell(
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
  );
}

class _SetupStep extends GetView<OnboardingController> {
  const _SetupStep();

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
        // One Obx for the field and the button: `enabled` and `busy` come from
        // the same value, so they have to change in the same frame.
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
                onPressed: controller.finish,
              ),
            ],
          ),
        ),
        const SizedBox(height: HavenSpacing.md),
        Text(
          'Adding a child and pairing a device comes next, from the family '
          'and pairing screens.',
          style: HavenText.caption,
        ),
      ],
    );
  }
}
