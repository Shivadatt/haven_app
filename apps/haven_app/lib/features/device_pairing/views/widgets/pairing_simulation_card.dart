import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';

/// Card on the main pairing page linking to the local pairing simulation.
final class PairingSimulationCard extends StatelessWidget {
  const PairingSimulationCard({required this.onOpenSimulation, super.key});

  final VoidCallback onOpenSimulation;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'LOCAL PAIRING SIMULATION',
      subtitle: 'Simulate child device pairing offline on this phone.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate a 6-digit pairing code on a simulated child device, '
            'validate expiry and countdown, and link a simulated device '
            'directly to a child in your local database.',
            style: HavenText.body,
          ),
          const SizedBox(height: HavenSpacing.md),
          HavenButton(
            label: 'Start Pairing Simulation',
            icon: Icons.play_arrow_outlined,
            primary: false,
            onPressed: onOpenSimulation,
          ),
        ],
      ),
    );
  }
}
