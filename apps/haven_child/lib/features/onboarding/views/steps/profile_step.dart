import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/child_field.dart';
import '../../controllers/onboarding_controller.dart';
import '../../data/child_avatars.dart';
import '../../data/child_profile_constants.dart';

/// Step 2 — display name (validated later by haven_core
/// `validateDisplayName`), the four age brackets from the parent app's
/// child-create screen, and a Material-icon avatar picker. No assets.
final class ProfileStep extends GetView<OnboardingController> {
  const ProfileStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChildField(
          label: 'Your first name',
          controller: controller.nameController,
          helper: 'It is stored on this device only.',
          maxLength: ChildProfileConstants.maxNameLength,
        ),
        const SizedBox(height: ChildSpacing.lg),
        Text('Age group', style: ChildText.headline),
        const SizedBox(height: ChildSpacing.xs),
        Obx(
          () => Wrap(
            spacing: ChildSpacing.sm,
            runSpacing: ChildSpacing.sm,
            children: [
              for (final bracket in ChildProfileConstants.ageBrackets)
                ChoiceChip(
                  label: Text('$bracket yrs'),
                  selected: controller.ageBracket.value == bracket,
                  onSelected: (_) => controller.ageBracket.value = bracket,
                ),
            ],
          ),
        ),
        const SizedBox(height: ChildSpacing.lg),
        Text('Pick an avatar', style: ChildText.headline),
        const SizedBox(height: ChildSpacing.xs),
        Obx(
          () => Wrap(
            spacing: ChildSpacing.sm,
            runSpacing: ChildSpacing.sm,
            children: [
              for (final option in ChildAvatars.options)
                ChoiceChip(
                  avatar: Icon(option.icon),
                  label: SizedBox(
                    width: ChildSpacing.xl,
                    child: Text(
                      option.name,
                      textAlign: TextAlign.center,
                      style: ChildText.caption,
                    ),
                  ),
                  selected: controller.avatar.value == option.name,
                  onSelected: (_) => controller.avatar.value = option.name,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
