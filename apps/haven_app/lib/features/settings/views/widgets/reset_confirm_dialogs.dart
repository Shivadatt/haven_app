import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/haven_colors.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';

/// Two-step modal confirmation for destructive full local database reset.
abstract final class ResetConfirmDialogs {
  /// Launches two-step modal confirmation flow. Returns true if both steps confirmed.
  static Future<bool> confirmFullReset(BuildContext context) async {
    // Step 1: Warning and explanation of data loss
    final step1 = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Reset All Local Data?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently erase all local tables on this device, including:',
              style: HavenText.body,
            ),
            const SizedBox(height: HavenSpacing.xs),
            const Text('• All family members and child profiles'),
            const Text('• All paired devices and device tokens'),
            const Text('• All screen time and app policy rules'),
            const Text('• All safe zones and location trails'),
            const SizedBox(height: HavenSpacing.sm),
            Text(
              'Personal data cannot be recovered after this action.',
              style: HavenText.body.copyWith(
                fontWeight: FontWeight.bold,
                color: HavenColors.bad,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: HavenColors.bad),
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Continue to Final Step'),
          ),
        ],
      ),
    );

    if (step1 != true) return false;

    // Step 2: Irreversible confirmation
    final step2 = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Final Confirmation'),
        content: Text(
          'Are you absolutely sure you want to proceed? All local records will '
          'be completely cleared and you will be signed out.',
          style: HavenText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: HavenColors.bad),
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Permanently Reset All Data'),
          ),
        ],
      ),
    );

    return step2 == true;
  }
}
