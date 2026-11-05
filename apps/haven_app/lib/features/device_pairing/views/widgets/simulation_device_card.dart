import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../data/simulation_models.dart';

/// Card displaying device details upon successful local simulation pairing.
final class SimulationDeviceCard extends StatelessWidget {
  const SimulationDeviceCard({
    required this.device,
    required this.onPairAnother,
    required this.onDone,
    super.key,
  });

  final SimulatedDevice device;
  final VoidCallback onPairAnother;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Pairing Successful!',
      subtitle: 'Simulated device created in local database.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Icon(Icons.check_circle, color: Colors.green, size: 48),
          ),
          const SizedBox(height: HavenSpacing.md),
          _DetailRow(label: 'Device Name', value: device.displayName),
          _DetailRow(label: 'Associated Child', value: device.childName),
          _DetailRow(label: 'Platform', value: device.platform.toUpperCase()),
          _DetailRow(label: 'Status', value: device.status.toUpperCase()),
          _DetailRow(label: 'Device ID', value: device.id),
          const SizedBox(height: HavenSpacing.lg),
          HavenButton(
            label: 'Pair Another Device',
            primary: false,
            onPressed: onPairAnother,
          ),
          const SizedBox(height: HavenSpacing.sm),
          HavenButton(
            label: 'Done',
            onPressed: onDone,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: HavenText.caption),
          Flexible(
            child: Text(
              value,
              style: HavenText.body.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
