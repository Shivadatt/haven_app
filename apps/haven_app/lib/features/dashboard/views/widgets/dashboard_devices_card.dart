import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/dashboard_controller.dart';
import '../../data/dashboard_repository.dart';

/// The registered devices card on the dashboard.
///
/// Offline it displays local registered devices with a `SIMULATED` badge on
/// demo/simulated devices; online it shows the honest refusal gap notice.
final class DashboardDevicesCard extends GetView<DashboardController> {
  const DashboardDevicesCard({required this.data, super.key});

  final DashboardData data;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Devices',
    child: Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.deviceGap.value != null)
            BlockedNotice.fromFailure(controller.deviceGap.value!)
          else if (data.devices.isNotEmpty) ...[
            for (final Device device in data.devices) ...[
              _DeviceRow(device),
              const SizedBox(height: HavenSpacing.sm),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: HavenSpacing.sm),
              child: Text(
                'No devices registered yet. Open Devices to pair a phone.',
                style: HavenText.body,
              ),
            ),
          const SizedBox(height: HavenSpacing.md),
          HavenButton(
            label: 'Open devices',
            primary: false,
            onPressed: controller.goToDevices,
          ),
          const SizedBox(height: HavenSpacing.sm),
          HavenButton(
            label: 'See reported app use',
            primary: false,
            onPressed: controller.goToActivity,
          ),
          const SizedBox(height: HavenSpacing.sm),
          HavenButton(
            label: 'See reported places',
            primary: false,
            onPressed: controller.goToLocation,
          ),
        ],
      ),
    ),
  );
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow(this.device);

  final Device device;

  bool get isSimulated =>
      device.displayName.contains('Simulated') ||
      device.id.startsWith('demo_');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HavenSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_android_rounded),
          const SizedBox(width: HavenSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.displayName, style: HavenText.body),
                Text(
                  // Stage 2 / D-5 R-9: the battery number here is the
                  // simulation's fabricated value, never a phone reading.
                  '${device.platform} · ${device.batteryLevel ?? 0}% battery '
                  '(DEMO — simulated values)',
                  style: HavenText.caption,
                ),
              ],
            ),
          ),
          if (isSimulated) ...[
            const StatusChip(label: 'SIMULATED', tone: StatusTone.warning),
            const SizedBox(width: HavenSpacing.xs),
          ],
          StatusChip(
            label: device.status ?? 'active',
            tone: (device.credentialRevokedAt != null || device.status == 'revoked')
                ? StatusTone.bad
                : StatusTone.good,
          ),
        ],
      ),
    );
  }
}
