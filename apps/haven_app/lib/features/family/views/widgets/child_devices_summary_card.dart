import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/child_profile_controller.dart';

/// Assigned devices summary card for a child profile.
final class ChildDevicesSummaryCard extends GetView<ChildProfileController> {
  const ChildDevicesSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Assigned devices',
      subtitle: 'Hardware actively linked to this child',
      child: Obx(() {
        if (controller.assignedDevices.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No devices are currently assigned to this child.',
                style: HavenText.body,
              ),
              if (controller.deviceGap.value != null) ...[
                const SizedBox(height: HavenSpacing.sm),
                BlockedNotice.fromFailure(controller.deviceGap.value!),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (final Device d in controller.assignedDevices)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone_android),
                title: Text(d.displayName, style: HavenText.title),
                subtitle: Text(
                  '${d.platform} • ${d.deviceStatus?.label ?? d.status}',
                  style: HavenText.caption,
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => controller.goToDevice(d.id),
              ),
          ],
        );
      }),
    );
  }
}
