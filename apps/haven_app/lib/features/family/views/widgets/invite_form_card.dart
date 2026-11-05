import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/family_invite_controller.dart';

/// Form card for inviting a new co-parent or guardian.
final class InviteFormCard extends GetView<FamilyInviteController> {
  const InviteFormCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Invite co-parent or guardian',
      subtitle: 'Add a partner to share parenting rules and view alerts.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => HavenField(
              label: 'Email address',
              controller: controller.email,
              keyboardType: TextInputType.emailAddress,
              helper: controller.emailError.value,
              enabled: !controller.busy.value,
            ),
          ),
          const SizedBox(height: HavenSpacing.md),
          Text('Select role', style: HavenText.caption),
          const SizedBox(height: HavenSpacing.xs),
          Obx(
            () => DropdownButtonFormField<String>(
              initialValue: controller.selectedRole.value,
              items: const [
                DropdownMenuItem(value: 'co_parent', child: Text('Co-Parent (Full control)')),
                DropdownMenuItem(value: 'guardian', child: Text('Guardian (Monitors only)')),
                DropdownMenuItem(value: 'parent', child: Text('Parent')),
              ],
              onChanged: controller.busy.value
                  ? null
                  : (String? val) {
                      if (val != null) controller.selectedRole.value = val;
                    },
            ),
          ),
          const SizedBox(height: HavenSpacing.md),
          Obx(() {
            final String? msg = controller.formMessage.value;
            if (msg == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: HavenSpacing.sm),
              child: Text(msg, style: HavenText.body),
            );
          }),
          Obx(
            () => HavenButton(
              label: 'Send invitation',
              busy: controller.busy.value,
              onPressed: controller.sendInvite,
            ),
          ),
        ],
      ),
    );
  }
}
