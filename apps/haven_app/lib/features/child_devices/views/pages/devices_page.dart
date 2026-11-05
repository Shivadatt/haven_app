import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../family/bindings/family_bindings.dart';
import '../../controllers/devices_controller.dart';
import '../dialogs/add_device_dialog.dart';
import '../widgets/device_list_card.dart';

/// Every device the family has paired.
final class DevicesPage extends GetView<DevicesController> {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Devices',
      onRefresh: controller.reload,
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
        DeviceListCard(devices: devices, onTap: controller.goToDevice),
        const SizedBox(height: HavenSpacing.md),
        const _PairingCard(),
      ],
    ),
  );
}

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

  Future<void> _openAdd(BuildContext context) async {
    final familyRepo = FamilyDependencies.ensureRepository();
    final bundle = (await familyRepo.load()).valueOrNull;
    final children = (bundle?.children ?? [])
        .map((c) => ChildOption(userId: c.userId, name: c.name))
        .toList();
    if (!context.mounted) return;
    await AddDeviceDialog.show(
      context,
      children: children,
      onAdd: ({
        required String displayName,
        required String childUserId,
        String platform = 'android',
        int? batteryLevel,
      }) async {
        final res = await controller.addDevice(
          displayName: displayName,
          childUserId: childUserId,
          platform: platform,
          batteryLevel: batteryLevel,
        );
        return res.isOk;
      },
    );
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Add a device',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A device joins when a child pairs it from their own phone, or you can '
          'register a simulated device for local testing.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        Wrap(
          spacing: HavenSpacing.sm,
          runSpacing: HavenSpacing.sm,
          children: [
            HavenButton(
              label: 'Open pairing',
              primary: false,
              onPressed: controller.goToPairing,
            ),
            HavenButton(
              label: 'Add simulated device',
              onPressed: () => _openAdd(context),
            ),
          ],
        ),
      ],
    ),
  );
}
