import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/device_detail_controller.dart';

/// Hardware, operating system, and app versions reported by the device.
final class DeviceHardwareCard extends GetView<DeviceDetailController> {
  const DeviceHardwareCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Hardware & software specs',
      subtitle: 'Technical profile as reported during check-in',
      // Stage 2 / D-5 R-9: the battery and charging values below come from the
      // local simulation, not a phone, so the card says so in its header.
      trailing: const StatusChip(
        label: 'DEMO — simulated values',
        tone: StatusTone.warning,
      ),
      child: Obx(() {
        final Device? dev = controller.device.value?.valueOrNull;
        if (dev == null) return const SizedBox.shrink();
        return Column(
          children: [
            _Row(label: 'Platform', value: dev.platform.capitalizeFirst ?? dev.platform),
            const SizedBox(height: HavenSpacing.xs),
            _Row(label: 'OS version', value: dev.androidVersion ?? 'Android (unspecified)'),
            const SizedBox(height: HavenSpacing.xs),
            _Row(label: 'Haven app version', value: dev.appVersion ?? '1.0.0 (offline)'),
            const SizedBox(height: HavenSpacing.xs),
            _Row(
              label: 'Battery',
              value: dev.batteryLevel != null
                  ? '${dev.batteryLevel}%${dev.isCharging == true ? " (Charging)" : ""}'
                  : 'Not reported',
            ),
          ],
        );
      }),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: HavenText.caption),
      Text(value, style: HavenText.body),
    ],
  );
}
