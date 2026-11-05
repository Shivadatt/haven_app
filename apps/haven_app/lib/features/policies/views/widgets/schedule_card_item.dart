import 'package:flutter/material.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../data/policy_schedules.dart';

/// Card row representing a single schedule entry.
class ScheduleCardItem extends StatelessWidget {
  const ScheduleCardItem({
    required this.schedule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final PolicySchedule schedule;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  IconData get _icon {
    switch (schedule.type) {
      case PolicyScheduleType.bedtime:
        return Icons.bedtime_outlined;
      case PolicyScheduleType.school:
        return Icons.school_outlined;
      case PolicyScheduleType.custom:
        return Icons.timer_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: HavenSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(HavenSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(_icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: HavenSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(schedule.name, style: HavenText.body.copyWith(fontWeight: FontWeight.bold)),
                      if (schedule.category != null) ...[
                        const SizedBox(width: HavenSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(schedule.category!, style: HavenText.caption),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${schedule.formattedTimes} · ${schedule.formattedDays}',
                    style: HavenText.caption,
                  ),
                  if (schedule.allowedApps.isNotEmpty)
                    Text(
                      '${schedule.allowedApps.length} allowed app exceptions',
                      style: HavenText.caption.copyWith(color: Theme.of(context).colorScheme.secondary),
                    ),
                ],
              ),
            ),
            Switch(
              value: schedule.isActive,
              onChanged: (_) => onToggle(),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit schedule',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Delete schedule',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
