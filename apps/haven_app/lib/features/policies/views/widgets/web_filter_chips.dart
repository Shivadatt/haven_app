import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../controllers/web_filter_controller.dart';
import '../../data/web_filter_models.dart';

class WebPresetRow extends StatelessWidget {
  const WebPresetRow({required this.controller, required this.isBlocked, super.key});
  final WebFilterController controller;
  final bool isBlocked;

  @override
  Widget build(BuildContext context) {
    const categories = [
      WebCategory.adult,
      WebCategory.gambling,
      WebCategory.social,
      WebCategory.gaming,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(right: HavenSpacing.xs),
            child: ActionChip(
              avatar: Icon(cat.icon, size: 16),
              label: Text('+ ${cat.label} Preset'),
              onPressed: () => controller.addCategoryPreset(cat, isBlocked: isBlocked),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class WebCategoryFilters extends StatelessWidget {
  const WebCategoryFilters({required this.controller, super.key});
  final WebFilterController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedCategory.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: WebCategory.values.map((cat) {
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
