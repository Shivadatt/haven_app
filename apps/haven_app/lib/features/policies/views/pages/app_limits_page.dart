import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/app_limits_controller.dart';
import '../../data/app_catalogue.dart';
import '../widgets/app_limits_banner.dart';
import '../widgets/limit_picker_dialog.dart';

final class AppLimitsPage extends GetView<AppLimitsController> {
  const AppLimitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'App Limits',
      onRefresh: controller.load,
      body: HavenPageBody(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final apps = controller.filteredApps;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: HavenSpacing.md),
            children: [
              const AppLimitsBanner(),
              const SizedBox(height: HavenSpacing.md),
              if (controller.devices.length > 1) ...[
                _DeviceSelector(controller: controller),
                const SizedBox(height: HavenSpacing.sm),
              ],
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search applications...',
                ),
                onChanged: controller.setSearchQuery,
              ),
              const SizedBox(height: HavenSpacing.xs),
              _CategoryChips(controller: controller),
              const SizedBox(height: HavenSpacing.sm),
              if (apps.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(HavenSpacing.lg),
                  child: Center(child: Text('No applications match your filter.')),
                )
              else
                ...apps.map((item) => _AppLimitTile(item: item, controller: controller)),
            ],
          );
        }),
      ),
    );
  }
}

class _DeviceSelector extends StatelessWidget {
  const _DeviceSelector({required this.controller});
  final AppLimitsController controller;

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

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.controller});
  final AppLimitsController controller;

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

class _AppLimitTile extends StatelessWidget {
  const _AppLimitTile({required this.item, required this.controller});
  final AppCatalogueItem item;
  final AppLimitsController controller;

  @override
  Widget build(BuildContext context) {
    final limit = controller.getLimitFor(item.packageName);
    final hasLimit = limit != null;

    return Card(
      margin: const EdgeInsets.only(bottom: HavenSpacing.xs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasLimit ? Colors.orange.shade100 : Colors.grey.shade200,
          child: Icon(item.icon, color: hasLimit ? Colors.orange.shade800 : Colors.grey.shade700),
        ),
        title: Text(item.name, style: HavenText.body),
        subtitle: Text(
          hasLimit ? '$limit minutes daily limit' : '${item.category.label} · No limit',
          style: HavenText.caption,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: hasLimit,
              onChanged: (enabled) => controller.toggleLimit(item.packageName, enabled),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit limit',
              onPressed: () => LimitPickerDialog.show(
                context,
                item: item,
                currentMinutes: limit,
                controller: controller,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
