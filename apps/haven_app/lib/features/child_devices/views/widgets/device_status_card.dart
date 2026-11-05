import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../core/utils/haven_time.dart';
import '../../controllers/device_detail_controller.dart';

/// Status explanation and pairing metadata for the device.
final class DeviceStatusCard extends GetView<DeviceDetailController> {
  const DeviceStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Status & enrollment history',
      subtitle: 'Enrollment state and communication health',
      child: Obx(() {
        final Device? dev = controller.device.value?.valueOrNull;
        if (dev == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip(
                  label: dev.isUsable ? 'Enrolled' : (dev.deviceStatus?.label ?? dev.status ?? 'Revoked'),
                  tone: dev.isUsable ? StatusTone.good : StatusTone.bad,
                ),
                const SizedBox(width: HavenSpacing.sm),
                Text(
                  dev.isUsable ? 'Enrolled & Healthy' : 'Action Required',
                  style: HavenText.title,
                ),
              ],
            ),
            const SizedBox(height: HavenSpacing.sm),
            Text(controller.statusExplanation, style: HavenText.body),
            const Divider(height: HavenSpacing.lg),
            _HistoryRow(
              label: 'Paired on',
              value: havenDay(dev.createdAt) ?? 'Initial setup',
            ),
            const SizedBox(height: HavenSpacing.xs),
            _HistoryRow(
              label: 'Last heartbeat',
              value: havenDay(dev.lastSeenAt) ?? 'Recently',
            ),
            if (dev.credentialRevokedAt != null) ...[
              const SizedBox(height: HavenSpacing.xs),
              _HistoryRow(
                label: 'Revoked on',
                value: havenDay(dev.credentialRevokedAt)!,
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.label, required this.value});
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
