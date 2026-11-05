import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../telemetry/views/widgets/trail_card.dart';
import '../../controllers/device_detail_controller.dart';
import '../widgets/device_child_card.dart';
import '../widgets/device_detail_cards.dart';
import '../widgets/device_hardware_card.dart';
import '../widgets/device_setup_checklist_card.dart';
import '../widgets/device_status_card.dart';

/// Comprehensive device detail page with specs, status, and setup checklist.
final class DeviceDetailPage extends GetView<DeviceDetailController> {
  const DeviceDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Device',
      body: HavenPageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!controller.hasDeviceId)
                const _NoDeviceNamed()
              else ...[
                const RecordCard(),
                const SizedBox(height: HavenSpacing.md),
                const DeviceChildCard(),
                const SizedBox(height: HavenSpacing.md),
                const DeviceStatusCard(),
                const SizedBox(height: HavenSpacing.md),
                const DeviceHardwareCard(),
                const SizedBox(height: HavenSpacing.md),
                const DeviceSetupChecklistCard(),
                const SizedBox(height: HavenSpacing.md),
                const ReportsCard(),
                const SizedBox(height: HavenSpacing.md),
                const TelemetryCard(),
                const SizedBox(height: HavenSpacing.md),
                const DeviceActionsCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NoDeviceNamed extends GetView<DeviceDetailController> {
  const _NoDeviceNamed();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'No device was named',
    child: Text(
      'Haven will not guess which device this screen was opened for. Open '
      'Devices and pick one from the list.',
      style: HavenText.body,
    ),
  );
}
