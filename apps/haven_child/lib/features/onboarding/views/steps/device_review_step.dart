import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/info_row.dart';
import '../../../../core/device/device_fact_rows.dart';
import '../../controllers/onboarding_controller.dart';

/// Step 3 — an honest summary of what the app can tell about this device,
/// plus the link to the full device screen (brief §4 C "Device review
/// (summary + link to device info)"). Fields without a real read say so in
/// the same words as everywhere else — the rows come from the shared
/// [DeviceFactRows] builder the device page itself uses.
final class DeviceReviewStep extends GetView<OnboardingController> {
  const DeviceReviewStep({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = DeviceFactRows.build(controller.deviceFacts);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Here is what Haven can tell about this device right now. '
          'Anything this build cannot read is shown as Unavailable — it is '
          'never guessed.',
          style: ChildText.body,
        ),
        const SizedBox(height: ChildSpacing.lg),
        for (final row in rows)
          ChildInfoRow(label: row.label, value: row.value),
        const SizedBox(height: ChildSpacing.md),
        const Text(DeviceFactRows.stageOneNote, style: ChildText.caption),
        const SizedBox(height: ChildSpacing.lg),
        OutlinedButton.icon(
          onPressed: controller.openDeviceDetails,
          icon: const Icon(Icons.phone_android_outlined),
          label: const Text('Open device details'),
        ),
      ],
    );
  }
}
