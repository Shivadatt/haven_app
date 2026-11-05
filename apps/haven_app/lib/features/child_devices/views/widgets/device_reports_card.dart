import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../controllers/device_detail_controller.dart';

/// Reports and secondary navigation actions for a device record.
class ReportsCard extends GetView<DeviceDetailController> {
  const ReportsCard({super.key});

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'What the backend holds for this device',
    subtitle:
        "Each screen reads rows addressed to this device's id, and each read "
        'works while the device row itself does not.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HavenButton(
          label: 'App use it reported',
          primary: false,
          onPressed: controller.goToActivity,
        ),
        const SizedBox(height: HavenSpacing.sm),
        HavenButton(
          label: 'Places it reported',
          primary: false,
          onPressed: controller.goToLocation,
        ),
        const SizedBox(height: HavenSpacing.sm),
        HavenButton(
          label: 'Instructions addressed to it',
          primary: false,
          onPressed: controller.goToCommands,
        ),
        const SizedBox(height: HavenSpacing.sm),
        HavenButton(
          label: 'Rule versions written for it',
          primary: false,
          onPressed: controller.goToPolicies,
        ),
      ],
    ),
  );
}
