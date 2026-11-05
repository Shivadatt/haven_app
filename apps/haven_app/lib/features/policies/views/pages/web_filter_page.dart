import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../controllers/web_filter_controller.dart';
import '../widgets/add_domain_dialog.dart';
import '../widgets/web_domain_tile.dart';
import '../widgets/web_filter_banner.dart';
import '../widgets/web_filter_chips.dart';

final class WebFilterPage extends GetView<WebFilterController> {
  const WebFilterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Website Filter',
      onRefresh: controller.load,
      body: HavenPageBody(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final isBlockedTab = controller.activeTabIndex.value == 0;
          final domains = controller.filteredDomains;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: HavenSpacing.md),
            children: [
              const WebFilterBanner(),
              const SizedBox(height: HavenSpacing.md),
              if (controller.devices.length > 1) ...[
                _DeviceDropdown(controller: controller),
                const SizedBox(height: HavenSpacing.sm),
              ],
              Card(
                child: SwitchListTile(
                  title: const Text('Enforce SafeSearch'),
                  subtitle: const Text('Enforces strict search on Google, Bing & YouTube'),
                  value: controller.config.value.safeSearchEnabled,
                  onChanged: controller.toggleSafeSearch,
                ),
              ),
              const SizedBox(height: HavenSpacing.md),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Text('Blocked (${controller.config.value.blockedDomains.length})'),
                    icon: const Icon(Icons.block, color: Colors.red),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Allowed (${controller.config.value.allowedDomains.length})'),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  ),
                ],
                selected: {controller.activeTabIndex.value},
                onSelectionChanged: (set) => controller.switchTab(set.first),
              ),
              const SizedBox(height: HavenSpacing.sm),
              WebPresetRow(controller: controller, isBlocked: isBlockedTab),
              const SizedBox(height: HavenSpacing.xs),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search domains...',
                ),
                onChanged: controller.setSearchQuery,
              ),
              const SizedBox(height: HavenSpacing.xs),
              WebCategoryFilters(controller: controller),
              const SizedBox(height: HavenSpacing.sm),
              if (domains.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(HavenSpacing.lg),
                  child: Center(
                    child: Text('No ${isBlockedTab ? 'blocked' : 'allowed'} domains found.'),
                  ),
                )
              else
                ...domains.map((d) => WebDomainTile(
                  domain: d,
                  isBlocked: isBlockedTab,
                  controller: controller,
                )),
              const SizedBox(height: HavenSpacing.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: Text('Add ${isBlockedTab ? 'Blocked' : 'Allowed'} Domain'),
                onPressed: () => AddDomainDialog.show(
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
  final WebFilterController controller;

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
