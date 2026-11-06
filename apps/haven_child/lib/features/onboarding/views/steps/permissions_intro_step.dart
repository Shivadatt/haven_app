import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/status_chip.dart';
import '../../../../core/permissions/child_permission.dart';
import '../../controllers/onboarding_controller.dart';

/// Step 4 — explanatory only, exactly per brief §4 C/E: this step requests
/// NOTHING, declares no permission, and says so plainly. The WHY copy is the
/// same text the permission dashboard renders, so one honest story per
/// capability.
final class PermissionsIntroStep extends GetView<OnboardingController> {
  const PermissionsIntroStep({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const ChildStatusChip(
        key: ValueKey('permissions-intro-no-requests'),
        label: 'No permission has been requested.',
        tone: StatusTone.neutral,
      ),
      const SizedBox(height: ChildSpacing.md),
      const Text(
        'Nothing is monitored yet. Android only lets an app do things like '
        'see screen time or location after a switch is turned on — and that '
        'never happens by itself. Here is what each future feature means, '
        'in plain words:',
        style: ChildText.body,
      ),
      const SizedBox(height: ChildSpacing.lg),
      for (final permission in ChildPermission.values)
        Padding(
          padding: const EdgeInsets.only(bottom: ChildSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(permission.icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: ChildSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(permission.label, style: ChildText.headline),
                    const SizedBox(height: ChildSpacing.xs),
                    Text(permission.why, style: ChildText.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      OutlinedButton.icon(
        onPressed: controller.openPermissionExplanations,
        icon: const Icon(Icons.privacy_tip_outlined),
        label: const Text('See the permission dashboard'),
      ),
    ],
  );
}
