import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/account_controller.dart';

/// Card for editing the parent's existing profile display name.
final class AccountNameCard extends GetView<AccountController> {
  const AccountNameCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Name shown to your family',
      subtitle: 'This is what your children’s devices see.',
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HavenField(
              label: 'Your name',
              controller: controller.displayName,
              maxLength: 60,
              helper: '2 to 60 characters.',
              enabled: !controller.busy.value,
            ),
            const SizedBox(height: HavenSpacing.md),
            HavenButton(
              label: 'Save name',
              busy: controller.busy.value,
              onPressed: controller.canSave ? controller.save : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Prompt shown when no profile row exists yet, allowing setup or creation.
final class AccountNeedsSetupCard extends GetView<AccountController> {
  const AccountNeedsSetupCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Haven has no record for this account yet',
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signing up does not create the account record on its own, so there '
              'is no name to show or change until setup runs.',
              style: HavenText.body,
            ),
            const SizedBox(height: HavenSpacing.md),
            HavenField(
              label: 'Your name',
              controller: controller.displayName,
              maxLength: 60,
              helper: '2 to 60 characters.',
              enabled: !controller.busy.value,
            ),
            const SizedBox(height: HavenSpacing.md),
            Wrap(
              spacing: HavenSpacing.sm,
              runSpacing: HavenSpacing.sm,
              children: [
                HavenButton(
                  label: 'Set up Haven',
                  onPressed: controller.goToSetup,
                ),
                HavenButton(
                  label: 'Create profile',
                  busy: controller.busy.value,
                  onPressed: controller.canCreate ? controller.createProfile : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
