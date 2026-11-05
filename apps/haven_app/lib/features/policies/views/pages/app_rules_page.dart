import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../controllers/app_rules_controller.dart';
import '../../data/app_catalogue.dart';
import '../widgets/add_app_rule_dialog.dart';
import '../widgets/app_rule_card.dart';
import '../widgets/app_rules_banner.dart';

final class AppRulesPage extends GetView<AppRulesController> {
  const AppRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'App Rules',
      onRefresh: controller.load,
      body: HavenPageBody(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final isBlockedTab = controller.activeTabIndex.value == 1;
          final apps = controller.filteredApps;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: HavenSpacing.md),
            children: [
              const AppRulesBanner(),
              const SizedBox(height: HavenSpacing.md),
              if (controller.devices.length > 1) ...[
                _DeviceDropdown(controller: controller),
                const SizedBox(height: HavenSpacing.sm),
              ],
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Text('Allowed (${controller.config.value.allowedApps.length})'),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Blocked (${controller.config.value.blockedApps.length})'),
                    icon: const Icon(Icons.block, color: Colors.red),
                  ),
                ],
                selected: {controller.activeTabIndex.value},
                onSelectionChanged: (set) => controller.switchTab(set.first),
              ),
              const SizedBox(height: HavenSpacing.sm),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search rules...',
                ),
                onChanged: controller.setSearchQuery,
              ),
              const SizedBox(height: HavenSpacing.xs),
              _CategoryFilters(controller: controller),
              const SizedBox(height: HavenSpacing.sm),
              if (apps.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(HavenSpacing.lg),
                  child: Center(
                    child: Text('No ${isBlockedTab ? 'blocked' : 'allowed'} apps found.'),
                  ),
                )
              else
                ...apps.map((item) => AppRuleCard(
                  item: item,
                  isBlocked: isBlockedTab,
                  controller: controller,
                )),
              const SizedBox(height: HavenSpacing.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: Text('Add ${isBlockedTab ? 'Blocked' : 'Allowed'} App'),
                onPressed: () => AddAppRuleDialog.show(
                  context,
                  controller: controller,
                  initialBlocked: isBlockedTab,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _DeviceDropdown extends StatelessWidget {
  const _DeviceDropdown({required this.controller});
  final AppRulesController controller;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: controller.selectedDeviceId.value.isEmpty
          ? null
          : controller.selectedDeviceId.value,
      decoration: const InputDecoration(labelText: 'Child Device'),
      items: controller.devices.map((d) {
        return DropdownMenuItem(value: d.id, child: Text(d.displayName));
      }).toList(),
      onChanged: (id) {
        if (id != null) controller.selectDevice(id);
      },
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({required this.controller});
  final AppRulesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedCategory.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: AppCategory.values.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: HavenSpacing.xs),
              child: FilterChip(
                label: Text(cat.label),
                selected: selected == cat,
                onSelected: (_) => controller.setCategory(cat),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}
