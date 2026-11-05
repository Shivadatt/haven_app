import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/policies_controller.dart';
import '../../data/policy_rules.dart';

/// Configures allowed apps, blocked apps, and per-app limits.
final class AppPoliciesCard extends GetView<PoliciesController> {
  const AppPoliciesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final blocked = controller.config.value.blockedApps;
      final allowed = controller.config.value.allowedApps;
      final limits = controller.config.value.appLimits;

      return SectionCard(
        title: 'App Restrictions & Limits',
        subtitle: '${blocked.length} blocked · ${allowed.length} allowed · ${limits.length} with limits',
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded),
          tooltip: 'Add app rule',
          onPressed: () => _showAddAppDialog(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (blocked.isNotEmpty) ...[
              Text('Blocked Apps', style: HavenText.body),
              const SizedBox(height: HavenSpacing.xs),
              Wrap(
                spacing: HavenSpacing.xs,
                runSpacing: HavenSpacing.xs,
                children: blocked.map((pkg) => Chip(
                  label: Text(pkg),
                  avatar: const Icon(Icons.block, size: 16, color: Colors.red),
                  onDeleted: () => controller.removeApp(pkg),
                )).toList(),
              ),
              const SizedBox(height: HavenSpacing.sm),
            ],
            if (allowed.isNotEmpty) ...[
              Text('Allowed Apps', style: HavenText.body),
              const SizedBox(height: HavenSpacing.xs),
              Wrap(
                spacing: HavenSpacing.xs,
                runSpacing: HavenSpacing.xs,
                children: allowed.map((pkg) => Chip(
                  label: Text(pkg),
                  avatar: const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                  onDeleted: () => controller.removeApp(pkg),
                )).toList(),
              ),
              const SizedBox(height: HavenSpacing.sm),
            ],
            if (limits.isNotEmpty) ...[
              Text('Per-App Time Limits', style: HavenText.body),
              for (final entry in limits.entries)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key, style: HavenText.body),
                  subtitle: Text('${entry.value} minutes daily'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => controller.removeAppLimit(entry.key),
                  ),
                ),
            ],
          ],
        ),
      );
    });
  }

  void _showAddAppDialog(BuildContext context) {
    final pkgCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: '30');
    final isBlocked = true.obs;
    final hasLimit = false.obs;
    final err = RxnString();

    Get.dialog<void>(
      AlertDialog(
        title: const Text('Add App Rule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pkgCtrl,
              decoration: const InputDecoration(
                labelText: 'Package Name',
                hintText: 'com.example.app',
              ),
            ),
            const SizedBox(height: HavenSpacing.xs),
            Obx(() => Row(
              children: [
                ChoiceChip(
                  label: const Text('Block'),
                  selected: isBlocked.value,
                  onSelected: (s) => isBlocked.value = true,
                ),
                const SizedBox(width: HavenSpacing.xs),
                ChoiceChip(
                  label: const Text('Allow'),
                  selected: !isBlocked.value,
                  onSelected: (s) => isBlocked.value = false,
                ),
              ],
            )),
            Obx(() => CheckboxListTile(
              title: const Text('Add daily time limit'),
              value: hasLimit.value,
              onChanged: (v) => hasLimit.value = v ?? false,
            )),
            Obx(() => hasLimit.value
                ? TextField(
                    controller: limitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Minutes limit'),
                  )
                : const SizedBox.shrink()),
            Obx(() => err.value == null
                ? const SizedBox.shrink()
                : Text(err.value!, style: const TextStyle(color: Colors.red))),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back<void>, child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final pkg = pkgCtrl.text.trim();
              final validation = PolicyRules.validatePackageName(pkg);
              if (validation != null) {
                err.value = validation;
                return;
              }
              controller.addApp(pkg, blocked: isBlocked.value);
              if (hasLimit.value) {
                final mins = int.tryParse(limitCtrl.text.trim()) ?? 30;
                controller.setAppLimit(pkg, mins);
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
