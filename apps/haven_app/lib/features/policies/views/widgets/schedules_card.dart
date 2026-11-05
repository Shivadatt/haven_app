import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart' show LocalIds;
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/policies_controller.dart';
import '../../data/policy_schedules.dart';

/// Downtime and school hours schedules card.
final class SchedulesCard extends GetView<PoliciesController> {
  const SchedulesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final schedules = controller.config.value.schedules;
      return SectionCard(
        title: 'Schedules & Focus Windows',
        subtitle: 'Configure bedtime and school focus hours',
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded),
          tooltip: 'Add schedule',
          onPressed: () => _showScheduleDialog(context),
        ),
        child: Column(
          children: [
            for (final sched in schedules) ...[
              _ScheduleRow(
                schedule: sched,
                onToggle: () => controller.toggleSchedule(sched.id),
                onEdit: () => _showScheduleDialog(context, existing: sched),
                onDelete: () => controller.deleteSchedule(sched.id),
              ),
              const Divider(height: HavenSpacing.md),
            ],
          ],
        ),
      );
    });
  }

  void _showScheduleDialog(BuildContext context, {PolicySchedule? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? 'Custom Schedule');
    final startCtrl = TextEditingController(text: existing?.startTime ?? '21:00');
    final endCtrl = TextEditingController(text: existing?.endTime ?? '07:00');
    final selectedDays = RxList<int>(existing?.days ?? [1, 2, 3, 4, 5, 6, 7]);
    final error = RxnString();

    Get.dialog<void>(
      AlertDialog(
        title: Text(existing == null ? 'Add Schedule' : 'Edit Schedule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Schedule Name'),
              ),
              const SizedBox(height: HavenSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      decoration: const InputDecoration(labelText: 'Start (HH:mm)'),
                    ),
                  ),
                  const SizedBox(width: HavenSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      decoration: const InputDecoration(labelText: 'End (HH:mm)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HavenSpacing.sm),
              const Text('Active Days:'),
              Obx(() => Wrap(
                spacing: 4,
                children: [
                  for (int i = 1; i <= 7; i++)
                    FilterChip(
                      label: Text(['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'][i]),
                      selected: selectedDays.contains(i),
                      onSelected: (sel) {
                        if (sel) {
                          selectedDays.add(i);
                        } else if (selectedDays.length > 1) {
                          selectedDays.remove(i);
                        }
                      },
                    ),
                ],
              )),
              Obx(() => error.value == null
                  ? const SizedBox.shrink()
                  : Text(error.value!, style: const TextStyle(color: Colors.red))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back<void>, child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!PolicySchedule.isValidTime(startCtrl.text.trim()) ||
                  !PolicySchedule.isValidTime(endCtrl.text.trim())) {
                error.value = 'Please enter valid times in HH:mm format.';
                return;
              }
              final schedule = PolicySchedule(
                id: existing?.id ?? LocalIds.create(),
                name: nameCtrl.text.trim(),
                type: existing?.type ?? PolicyScheduleType.custom,
                startTime: startCtrl.text.trim(),
                endTime: endCtrl.text.trim(),
                days: selectedDays.toList(),
                isActive: existing?.isActive ?? true,
              );
              controller.saveSchedule(schedule);
              Get.back<void>();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.schedule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final PolicySchedule schedule;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch(value: schedule.isActive, onChanged: (_) => onToggle()),
        const SizedBox(width: HavenSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(schedule.name, style: HavenText.body),
              Text(
                '${schedule.startTime} - ${schedule.endTime} · ${schedule.formattedDays}',
                style: HavenText.caption,
              ),
            ],
          ),
        ),
        IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
        IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: onDelete),
      ],
    );
  }
}
