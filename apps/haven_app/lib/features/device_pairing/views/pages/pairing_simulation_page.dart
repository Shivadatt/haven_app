import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_colors.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/pairing_simulation_controller.dart';
import '../widgets/pairing_simulation_forms.dart';
import '../widgets/simulation_device_card.dart';

/// Full screen interface for local device pairing simulation.
final class PairingSimulationPage extends GetView<PairingSimulationController> {
  const PairingSimulationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Device Pairing',
      body: HavenPageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
          child: Obx(() {
            if (controller.createdDevice.value != null) {
              return SimulationDeviceCard(
                device: controller.createdDevice.value!,
                onPairAnother: controller.reset,
                onDone: controller.done,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _HeaderBanner(),
                const SizedBox(height: HavenSpacing.md),
                ChildDeviceSimulatorCard(controller: controller),
                const SizedBox(height: HavenSpacing.md),
                ParentEntryFormCard(controller: controller),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HavenSpacing.sm),
      decoration: BoxDecoration(
        color: HavenColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: HavenColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.developer_mode, color: HavenColors.primary),
          const SizedBox(width: HavenSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOCAL PAIRING SIMULATION',
                  style: HavenText.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: HavenColors.primary,
                  ),
                ),
                Text(
                  'Simulate child device pairing offline on this phone.',
                  style: HavenText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
