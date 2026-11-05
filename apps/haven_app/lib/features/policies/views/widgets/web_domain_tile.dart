import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/web_filter_controller.dart';
import '../../data/web_filter_models.dart';
import 'edit_domain_dialog.dart';

class WebDomainTile extends StatelessWidget {
  const WebDomainTile({
    required this.domain,
    required this.isBlocked,
    required this.controller,
    super.key,
  });

  final String domain;
  final bool isBlocked;
  final WebFilterController controller;

  void _confirmDelete(BuildContext context) {
    Get.dialog<void>(
      AlertDialog(
        title: const Text('Remove Domain Rule?'),
        content: Text('Remove rule for $domain?'),
        actions: [
          TextButton(onPressed: Get.back<void>, child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              controller.removeDomain(domain);
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
    final cat = WebFilterModels.categorize(domain);
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
        title: Text(domain, style: HavenText.body),
        subtitle: Text(cat.label, style: HavenText.caption),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit Domain',
              onPressed: () => EditDomainDialog.show(
                context,
                controller: controller,
                oldDomain: domain,
                isBlocked: isBlocked,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Remove Domain',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }
}
