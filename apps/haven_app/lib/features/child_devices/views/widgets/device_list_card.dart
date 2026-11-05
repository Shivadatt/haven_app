import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../core/utils/haven_time.dart';

/// The paired devices this account could read.
final class DeviceListCard extends StatelessWidget {
  const DeviceListCard({required this.devices, this.onTap, super.key});

  final List<Device> devices;
  final void Function(String deviceId)? onTap;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Paired devices',
    subtitle:
        '${devices.length} ${devices.length == 1 ? 'device' : 'devices'} read '
        'from the backend.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final Device device in devices) ...[
          DeviceRow(
            device,
            onTap: onTap == null ? null : () => onTap!(device.id),
          ),
          if (device != devices.last) const SizedBox(height: HavenSpacing.md),
        ],
      ],
    ),
  );
}

final class DeviceRow extends StatelessWidget {
  const DeviceRow(this.device, {super.key, this.onTap});

  final Device device;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isSimulated = device.installationId.startsWith('sim');
    final Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      device.displayName.isEmpty
                          ? 'A device with no name yet'
                          : device.displayName,
                      style: HavenText.body,
                    ),
                  ),
                  if (isSimulated) ...[
                    const SizedBox(width: HavenSpacing.xs),
                    const StatusChip(
                      label: 'SIMULATED DEVICE',
                      tone: StatusTone.warning,
                    ),
                  ],
                ],
              ),
              Text(
                _seenAndBattery(),
                style: HavenText.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        StatusChip(label: _statusLabel, tone: _tone),
      ],
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }

  String _seenAndBattery() {
    final String seen = _seen();
    if (device.batteryLevel != null) {
      return '$seen • ${device.batteryLevel}% battery';
    }
    return seen;
  }

  String _seen() => device.lastSeenAt == null
      ? 'The backend has not reported hearing from it'
      : 'Last seen ${havenTimeAgo(device.lastSeenAt)}';

  String get _statusLabel => device.deviceStatus?.label ?? 'No status recorded';

  StatusTone get _tone {
    switch (device.deviceStatus) {
      case DeviceStatus.active:
        return device.isUsable ? StatusTone.good : StatusTone.bad;
      case DeviceStatus.pending:
        return StatusTone.warning;
      case DeviceStatus.revoked:
        return StatusTone.neutral;
      default:
        return StatusTone.neutral;
    }
  }
}
