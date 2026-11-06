import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/info_row.dart';
import '../../../../shared/components/status_chip.dart';
import '../../controllers/onboarding_controller.dart';
import '../../data/child_avatars.dart';

/// Step 5 — the one write of this flow. The button is busy-guarded while a
/// create is in flight, and the repository's create-once rule is the second
/// layer, so a fast double tap cannot make two profiles.
final class CompletionStep extends GetView<OnboardingController> {
  const CompletionStep({super.key});

  @override
  Widget build(BuildContext context) {
    final avatar = ChildAvatars.resolve(
      controller.avatar.value.isEmpty ? null : controller.avatar.value,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              avatar.icon,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: ChildSpacing.md),
            Expanded(
              child: Text(
                controller.nameController.text.trim(),
                style: ChildText.title,
              ),
            ),
          ],
        ),
        const SizedBox(height: ChildSpacing.md),
        ChildInfoRow(label: 'Age group', value: controller.ageBracket.value),
        ChildInfoRow(
          label: 'Avatar',
          value: avatar.name,
          emphasizeUnavailable: false,
        ),
        const SizedBox(height: ChildSpacing.md),
        const Text(
          'Haven will save this on this device only. It happens once — '
          'the same profile cannot be created twice, and nothing here goes '
          'to a server.',
          style: ChildText.body,
        ),
        const SizedBox(height: ChildSpacing.lg),
        const ChildStatusChip(
          key: ValueKey('completion-not-connected'),
          label: 'Parent connection: Not connected',
          tone: StatusTone.neutral,
        ),
        const SizedBox(height: ChildSpacing.lg),
        Obx(
          () => FilledButton.icon(
            onPressed: controller.isSubmitting.value ? null : controller.finish,
            icon: const Icon(Icons.check),
            label: Text(
              controller.isSubmitting.value ? 'Creating…' : 'Create my profile',
            ),
          ),
        ),
      ],
    );
  }
}
