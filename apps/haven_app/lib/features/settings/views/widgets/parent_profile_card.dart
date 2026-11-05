import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_text.dart';
import '../../controllers/settings_controller.dart';

/// Displays parent profile information and name editing.
final class ParentProfileCard extends GetView<SettingsController> {
  const ParentProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = controller.parentProfile.value;
      final name = profile?.displayName.isNotEmpty == true
          ? profile!.displayName
          : 'Parent Profile';
      final email = profile?.email.isNotEmpty == true
          ? profile!.email
          : 'Local Parent Account';

      return SectionCard(
        title: 'Parent Profile',
        subtitle: '$name · $email',
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit name',
          onPressed: () => _showEditNameDialog(context, profile?.displayName ?? ''),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your profile manages family controls and device rules locally on this device.',
              style: HavenText.caption,
            ),
          ],
        ),
      );
    });
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);

    Get.dialog<void>(
      AlertDialog(
        title: const Text('Edit Parent Name'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Display Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: Get.back<void>, child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                controller.updateParentName(newName);
              }
              Get.back<void>();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
