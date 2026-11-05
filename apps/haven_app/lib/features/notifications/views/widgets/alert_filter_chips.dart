import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../controllers/notifications_controller.dart';

/// Horizontal category filter chips for safety alert listing.
final class AlertFilterChips extends GetView<NotificationsController> {
  const AlertFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    const categories = [
      ('all', 'All'),
      ('geofence', 'Safe Places'),
      ('battery', 'Battery'),
      ('other', 'Other'),
    ];

    return Obx(() {
      final current = controller.selectedCategory.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (id, label) in categories) ...[
              FilterChip(
                label: Text(label),
                selected: current == id,
                onSelected: (_) => controller.selectCategory(id),
              ),
              const SizedBox(width: HavenSpacing.xs),
            ],
          ],
        ),
      );
    });
  }
}
