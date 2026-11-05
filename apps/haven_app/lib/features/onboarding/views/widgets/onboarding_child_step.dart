import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_colors.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/onboarding_controller.dart';

/// Step 3: Initial child profile creation with name, age group, and avatar.
final class OnboardingChildStep extends GetView<OnboardingController> {
  const OnboardingChildStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add your child', style: HavenText.headline),
        const SizedBox(height: HavenSpacing.sm),
        Text(
          'Set up your child’s profile. Protection rules and device pairing '
          'will attach to this profile.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HavenField(
                label: 'Child name',
                controller: controller.childName,
                maxLength: 60,
                helper: '2 to 60 characters.',
                enabled: !controller.isBusy,
              ),
              const SizedBox(height: HavenSpacing.md),
              Text('Age group', style: HavenText.headline),
              const SizedBox(height: HavenSpacing.xs),
              Wrap(
                spacing: HavenSpacing.sm,
                children: ChildAgeGroup.values.map((group) {
                  final bool selected = controller.ageGroup.value == group;
                  return ChoiceChip(
                    label: Text(group.label),
                    selected: selected,
                    onSelected: controller.isBusy
                        ? null
                        : (_) => controller.ageGroup.value = group,
                  );
                }).toList(),
              ),
              const SizedBox(height: HavenSpacing.md),
              Text('Choose an avatar', style: HavenText.headline),
              const SizedBox(height: HavenSpacing.xs),
              Wrap(
                spacing: HavenSpacing.sm,
                children: ChildAvatar.values.map((item) {
                  final bool selected = controller.avatar.value == item;
                  return InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: controller.isBusy
                        ? null
                        : () => controller.avatar.value = item,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: HavenSpacing.sm,
                        vertical: HavenSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selected
                              ? HavenColors.primary
                              : HavenColors.outline,
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${item.emoji} ${item.label}'),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: HavenSpacing.lg),
              if (controller.message.value != null) ...[
                Text(controller.message.value!, style: HavenText.body),
                const SizedBox(height: HavenSpacing.sm),
              ],
              HavenButton(
                label: 'Continue to device setup',
                expand: true,
                busy: controller.isBusy,
                onPressed: controller.submitChild,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
