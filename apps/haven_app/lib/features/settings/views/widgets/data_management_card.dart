import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_colors.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/settings_controller.dart';
import 'reset_confirm_dialogs.dart';

/// Data management card providing sign-out, demo reset, and full database reset.
final class DataManagementCard extends GetView<SettingsController> {
  const DataManagementCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Session & Local Data Management',
      subtitle: 'Manage local storage, demo fixtures, and session state',
      child: Obx(() {
        final busy = controller.isResetting.value;
        final msg = controller.message.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (msg != null) ...[
              Text(msg, style: HavenText.caption.copyWith(color: HavenColors.primary)),
              const SizedBox(height: HavenSpacing.sm),
            ],
            OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out of Local Session'),
              onPressed: busy ? null : () => _confirmSignOut(context),
            ),
            const SizedBox(height: HavenSpacing.sm),
            OutlinedButton.icon(
              icon: const Icon(Icons.cleaning_services_rounded),
              label: const Text('Reset Demo Data Only'),
              onPressed: busy ? null : () => _confirmDemoReset(context),
            ),
            const SizedBox(height: HavenSpacing.sm),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: HavenColors.bad),
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Reset All Local Data'),
              onPressed: busy ? null : () => _triggerFullReset(context),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final yes = await ConfirmSheet.confirm(
      context,
      title: 'Sign out of local session?',
      body: 'Your family database and configured device rules remain safely on this device.',
      confirmLabel: 'Sign out',
    );
    if (yes) controller.signOut();
  }

  Future<void> _confirmDemoReset(BuildContext context) async {
    final yes = await ConfirmSheet.confirm(
      context,
      title: 'Reset Demo Data?',
      body: 'This removes sample demo records only. All your personal families, devices, and policies are kept.',
      confirmLabel: 'Clear demo records',
    );
    if (yes) controller.resetDemoData();
  }

  Future<void> _triggerFullReset(BuildContext context) async {
    final confirmed = await ResetConfirmDialogs.confirmFullReset(context);
    if (confirmed) controller.resetAllData();
  }
}
