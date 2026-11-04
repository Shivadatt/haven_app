import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/devices_controller.dart';
import '../widgets/device_list_card.dart';

/// Every device the family has paired.
///
/// In this build the read is refused, and the refusal is shown in full instead of
/// an empty list — the difference matters, because "nothing is paired" and "this
/// app cannot see the shelf" call for completely different actions.
final class DevicesPage extends GetView<DevicesController> {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Devices',
      onRefresh: controller.refresh,
      body: HavenPageBody(
        child: Obx(
          () => StateView<List<Device>>(
            isLoading: controller.isLoading.value,
            result: controller.devices.value,
            onRetry: controller.load,
            empty: () => const _NoDevices(),
            onData: (BuildContext context, List<Device> devices) =>
                _Content(devices),
          ),
        ),
      ),
    );
  }
}

class _Content extends GetView<DevicesController> {
  const _Content(this.devices);

  final List<Device> devices;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeviceListCard(devices: devices),
        const SizedBox(height: HavenSpacing.md),
        const _PairingCard(),
      ],
    ),
  );
}

/// Nothing is paired, which is a different fact from the read being refused.
class _NoDevices extends GetView<DevicesController> {
  const _NoDevices();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionCard(
        title: 'No device is paired yet',
        child: Text(
          'The backend returned an empty list for this family, so no child '
          'phone is reporting to Haven.',
          style: HavenText.body,
        ),
      ),
      const SizedBox(height: HavenSpacing.md),
      const _PairingCard(),
    ],
  );
}

class _PairingCard extends GetView<DevicesController> {
  const _PairingCard();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Add a device',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A device joins when a child pairs it from their own phone. Haven '
          'shows what pairing needs on the pairing screen.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(
          label: 'Open pairing',
          primary: false,
          onPressed: controller.goToPairing,
        ),
      ],
    ),
  );
}
