import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/policies_controller.dart';
import '../../data/policy_rules.dart';

/// Configures allowed domains and blocked domains with format validation.
final class WebsitePoliciesCard extends GetView<PoliciesController> {
  const WebsitePoliciesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final blocked = controller.config.value.blockedDomains;
      final allowed = controller.config.value.allowedDomains;

      return SectionCard(
        title: 'Website & Content Filters',
        subtitle: '${blocked.length} blocked domains · ${allowed.length} allowed domains',
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded),
          tooltip: 'Add domain rule',
          onPressed: () => _showAddDomainDialog(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (blocked.isNotEmpty) ...[
              Text('Blocked Domains', style: HavenText.body),
              const SizedBox(height: HavenSpacing.xs),
              Wrap(
                spacing: HavenSpacing.xs,
                runSpacing: HavenSpacing.xs,
                children: blocked.map((dom) => Chip(
                  label: Text(dom),
                  avatar: const Icon(Icons.block, size: 16, color: Colors.red),
                  onDeleted: () => controller.removeDomain(dom),
                )).toList(),
              ),
              const SizedBox(height: HavenSpacing.sm),
            ],
            if (allowed.isNotEmpty) ...[
              Text('Allowed Domains', style: HavenText.body),
              const SizedBox(height: HavenSpacing.xs),
              Wrap(
                spacing: HavenSpacing.xs,
                runSpacing: HavenSpacing.xs,
                children: allowed.map((dom) => Chip(
                  label: Text(dom),
                  avatar: const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                  onDeleted: () => controller.removeDomain(dom),
                )).toList(),
              ),
            ],
            const SizedBox(height: HavenSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.toNamed(AppRoutes.webFilter, arguments: controller.deviceId),
                child: const Text('Manage Web Filters'),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showAddDomainDialog(BuildContext context) {
    final domainCtrl = TextEditingController();
    final isBlocked = true.obs;
    final err = RxnString();

    Get.dialog<void>(
      AlertDialog(
        title: const Text('Add Domain Rule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: domainCtrl,
              decoration: const InputDecoration(
                labelText: 'Domain Name',
                hintText: 'example.com',
              ),
              onChanged: (_) => err.value = null,
            ),
            const SizedBox(height: HavenSpacing.xs),
            Obx(() => Row(
              children: [
                ChoiceChip(
                  label: const Text('Block'),
                  selected: isBlocked.value,
                  onSelected: (_) => isBlocked.value = true,
                ),
                const SizedBox(width: HavenSpacing.xs),
                ChoiceChip(
                  label: const Text('Allow'),
                  selected: !isBlocked.value,
                  onSelected: (_) => isBlocked.value = false,
                ),
              ],
            )),
            Obx(() => err.value == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(err.value!, style: const TextStyle(color: Colors.red)),
                  )),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back<void>, child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final domain = domainCtrl.text.trim();
              final validation = PolicyRules.validateDomain(domain);
              if (validation != null) {
                err.value = validation;
                return;
              }
              controller.addDomain(domain, blocked: isBlocked.value);
              Get.back<void>();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
