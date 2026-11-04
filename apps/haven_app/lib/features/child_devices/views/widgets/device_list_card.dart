import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../core/utils/haven_time.dart';

/// The paired devices this account could read.
///
/// Only what the row says is said: the status column, the platform the device
/// reported, and the last time the backend heard from it. Nothing here infers
/// "online" from a recent timestamp, and no field of a device row that looks
/// like a credential is ever rendered.
final class DeviceListCard extends StatelessWidget {
  const DeviceListCard({required this.devices, super.key});

  final List<Device> devices;

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
          DeviceRow(device),
          if (device != devices.last) const SizedBox(height: HavenSpacing.md),
        ],
      ],
    ),
  );
}

final class DeviceRow extends StatelessWidget {
  const DeviceRow(this.device, {super.key});

  final Device device;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.displayName.isEmpty
                  ? 'A device with no name yet'
                  : device.displayName,
              style: HavenText.body,
            ),
            Text(
              _seen(),
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

  String _seen() => device.lastSeenAt == null
      ? 'The backend has not reported hearing from it'
      : 'Last seen ${havenTimeAgo(device.lastSeenAt)}';

  String get _statusLabel => device.deviceStatus?.label ?? 'No status recorded';

  /// A revoked row is the truth about a device that used to be trusted; a
  /// pending one is work the parent still has to finish.
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
