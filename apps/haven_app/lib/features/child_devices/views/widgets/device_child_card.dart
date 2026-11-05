import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../family/bindings/family_bindings.dart';
import '../../controllers/device_detail_controller.dart';
import '../dialogs/add_device_dialog.dart';

/// Card showing current child assignment and providing reassignment dialog.
final class DeviceChildCard extends GetView<DeviceDetailController> {
  const DeviceChildCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Child assignment',
      subtitle: 'Who uses this device in the family',
      child: Obx(() {
        final Device? dev = controller.device.value?.valueOrNull;
        if (dev == null) return const SizedBox.shrink();
        final Profile? child = controller.assignedChild.value;

        return Row(
          children: [
            Text(child?.avatar ?? '📱', style: const TextStyle(fontSize: 26)),
            const SizedBox(width: HavenSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child != null ? child.displayName : 'Not assigned to a child',
                    style: HavenText.title,
                  ),
                  Text(
                    child?.ageBracket != null ? 'Ages ${child!.ageBracket}' : 'Unlinked',
                    style: HavenText.caption,
                  ),
                ],
              ),
            ),
            HavenButton(
              label: child == null ? 'Assign' : 'Reassign',
              primary: false,
              onPressed: () => _pickChild(context, dev),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _pickChild(BuildContext context, Device device) async {
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
}
