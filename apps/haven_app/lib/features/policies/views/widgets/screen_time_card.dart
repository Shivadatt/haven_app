import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/policies_controller.dart';
import '../../data/policy_rules.dart';

/// Screen time budget configuration card.
final class ScreenTimeCard extends GetView<PoliciesController> {
  const ScreenTimeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final minutes = controller.config.value.dailyScreenTimeMinutes;
      final hours = (minutes / 60).toStringAsFixed(1);
      return SectionCard(
        title: 'Daily Screen Time Budget',
        subtitle: '$minutes minutes ($hours hours) allowed per day',
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit daily limit',
          onPressed: () => _showEditDialog(context, minutes),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: minutes.toDouble().clamp(0, 1440),
                    min: 0,
                    max: 1440,
                    divisions: 48,
                    label: '$minutes mins',
                    onChanged: (val) => controller.updateDailyLimit(val.toInt()),
                  ),
                ),
                Text('$minutes m', style: HavenText.body),
              ],
            ),
            const SizedBox(height: HavenSpacing.xs),
            Wrap(
              spacing: HavenSpacing.xs,
              children: [60, 120, 180, 240].map((preset) {
                final isSelected = minutes == preset;
                return ChoiceChip(
                  label: Text('${preset ~/ 60}h'),
                  selected: isSelected,
                  onSelected: (_) => controller.updateDailyLimit(preset),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }

  void _showEditDialog(BuildContext context, int currentMinutes) {
    final textController = TextEditingController(text: '$currentMinutes');
    final errorText = RxnString();

    Get.dialog<void>(
      AlertDialog(
        title: const Text('Edit Daily Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter daily limit in minutes (0 - 1440):'),
            const SizedBox(height: HavenSpacing.sm),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                suffixText: 'mins',
                border: const OutlineInputBorder(),
                errorText: errorText.value,
              ),
              onChanged: (_) => errorText.value = null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(textController.text.trim());
              final validation = PolicyRules.validateMinutesLimit(parsed);
              if (validation != null) {
                errorText.value = validation;
                return;
              }
              controller.updateDailyLimit(parsed!);
              Get.back<void>();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
