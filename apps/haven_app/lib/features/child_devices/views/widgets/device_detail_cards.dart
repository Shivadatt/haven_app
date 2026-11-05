import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_core/haven_core.dart' show BlockedFailure, HavenFailure;
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../family/bindings/family_bindings.dart';
import '../../controllers/device_detail_controller.dart';
import '../dialogs/add_device_dialog.dart';
import '../dialogs/rename_device_dialog.dart';
import 'device_list_card.dart';

export 'device_reports_card.dart';

class RecordCard extends GetView<DeviceDetailController> {
  const RecordCard({super.key});

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'What this device is',
    child: Obx(() {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(HavenSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final HavenFailure? failure = controller.device.value?.failureOrNull;
      if (failure is BlockedFailure) return BlockedNotice.fromFailure(failure);
      if (failure != null) return DeviceRetry(failure: failure);
      final Device? read = controller.device.value?.valueOrNull;
      if (read == null) {
        return const Text('The backend returned no device for this id.');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DeviceRow(read),
          const SizedBox(height: HavenSpacing.sm),
          Wrap(
            spacing: HavenSpacing.sm,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Rename'),
                onPressed: () => RenameDeviceDialog.show(
                  context,
                  initialName: read.displayName,
                  onRename: controller.rename,
                ),
              ),
              _AssignChildButton(device: read),
            ],
          ),
        ],
      );
    }),
  );
}

class _AssignChildButton extends GetView<DeviceDetailController> {
  const _AssignChildButton({required this.device});

  final Device device;

  Future<void> _pickChild(BuildContext context) async {
    final familyRepo = FamilyDependencies.ensureRepository();
    final bundle = (await familyRepo.load()).valueOrNull;
    final children = (bundle?.children ?? [])
        .map((c) => ChildOption(userId: c.userId, name: c.name))
        .toList();
    if (!context.mounted) return;
    if (children.isEmpty) {
      Get.snackbar('Family', 'No children found in this family.');
      return;
    }
    final String? picked = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => SimpleDialog(
        title: const Text('Assign to child'),
        children: [
          for (final ChildOption opt in children)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(opt.userId),
              child: Row(
                children: [
                  Text(opt.name),
                  if (opt.userId == device.childUserId) ...[
                    const Spacer(),
                    const Icon(Icons.check, size: 18),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
    if (picked != null) {
      await controller.assignChild(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.person_outline, size: 16),
      label: const Text('Assign child'),
      onPressed: () => _pickChild(context),
    );
  }
}

class DeviceRetry extends GetView<DeviceDetailController> {
  const DeviceRetry({super.key, required this.failure});

  final HavenFailure failure;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(failure.message, style: HavenText.body),
      if (failure.retryable) ...[
        const SizedBox(height: HavenSpacing.md),
        HavenButton(label: 'Try again', onPressed: controller.load),
      ],
    ],
  );
}

class DeviceActionsCard extends GetView<DeviceDetailController> {
  const DeviceActionsCard({super.key});

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'What you could do with it',
    subtitle:
        'Taking a device out of Haven, or asking it to re-check its rules.',
    child: Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.revokeGap.value != null) ...[
            BlockedNotice.fromFailure(controller.revokeGap.value!),
            const SizedBox(height: HavenSpacing.sm),
          ] else ...[
            HavenButton(
              label: 'Unlink device',
              primary: false,
              busy: controller.isUnlinking.value,
              onPressed: () async {
                final bool agreed = await ConfirmSheet.confirm(
                  context,
                  title: 'Unlink this device?',
                  body:
                      'This device will be removed from your family and stop '
                      'reporting to Haven.',
                  confirmLabel: 'Unlink device',
                  destructive: true,
                );
                if (agreed) {
                  await controller.unlinkDevice();
                }
              },
            ),
            const SizedBox(height: HavenSpacing.sm),
          ],
          if (controller.recoveryGap.value != null)
            BlockedNotice.fromFailure(controller.recoveryGap.value!),
        ],
      ),
    ),
  );
}
