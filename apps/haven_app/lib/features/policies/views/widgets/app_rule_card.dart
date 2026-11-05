import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/app_rules_controller.dart';
import '../../data/app_catalogue.dart';

class AppRuleCard extends StatelessWidget {
  const AppRuleCard({
    required this.item,
    required this.isBlocked,
    required this.controller,
    super.key,
  });

  final AppCatalogueItem item;
  final bool isBlocked;
  final AppRulesController controller;

  void _confirmDelete(BuildContext context) {
    Get.dialog<void>(
      AlertDialog(
        title: const Text('Remove App Rule?'),
        content: Text('Remove rule for ${item.name}?'),
        actions: [
          TextButton(onPressed: Get.back<void>, child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              controller.removeAppRule(item.packageName);
              Get.back<void>();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: HavenSpacing.xs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isBlocked ? Colors.red.shade50 : Colors.green.shade50,
          child: Icon(
            isBlocked ? Icons.block : Icons.check_circle_outline,
            color: isBlocked ? Colors.red : Colors.green,
          ),
        ),
        title: Text(item.name, style: HavenText.body),
        subtitle: Text(
          '${item.category.label} · ${item.packageName}',
          style: HavenText.caption,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.timer_outlined, size: 20),
              tooltip: 'Set Time Limit',
              onPressed: () => controller.goToAppLimits(item.packageName),
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz, size: 20),
              tooltip: isBlocked ? 'Move to Allowed' : 'Move to Blocked',
              onPressed: () => controller.toggleAppStatus(item.packageName),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Delete Rule',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }
}
