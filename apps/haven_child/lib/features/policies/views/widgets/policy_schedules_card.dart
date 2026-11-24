import 'package:flutter/material.dart';
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/status_chip.dart';

/// Renders configured downtime schedules and active schedule indicators.
final class PolicySchedulesCard extends StatelessWidget {
  const PolicySchedulesCard({
    required this.schedules,
    this.activeSchedules = const <PolicySchedule>[],
    super.key,
  });

  final List<PolicySchedule> schedules;
  final List<PolicySchedule> activeSchedules;

  static const String scheduleNotice =
      'Scheduled downtime window. Device lockout is not enforced on this build.';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ChildSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Downtime & schedules', style: ChildText.headline),
            const SizedBox(height: ChildSpacing.md),
            if (schedules.isEmpty)
              Text('No downtime schedules configured.', style: ChildText.body)
            else ...[
              for (var i = 0; i < schedules.length; i++) ...[
                if (i > 0) const Divider(height: ChildSpacing.lg),
                _ScheduleRow(
                  schedule: schedules[i],
                  isActive: activeSchedules.any(
                    (active) => active.id == schedules[i].id,
                  ),
                ),
              ],
              const SizedBox(height: ChildSpacing.sm),
              Text(scheduleNotice, style: ChildText.caption),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.schedule, required this.isActive});

  final PolicySchedule schedule;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(schedule.name, style: ChildText.body),
              const SizedBox(height: ChildSpacing.xs),
              Text(
                '${schedule.startTime} – ${schedule.endTime} · ${_formatDays(schedule.days)}',
                style: ChildText.caption,
              ),
            ],
          ),
        ),
        if (isActive)
          const ChildStatusChip(
            key: ValueKey('schedule-active-chip'),
            label: 'Active now',
            tone: StatusTone.warning,
          ),
      ],
    );
  }

  String _formatDays(List<int> days) {
    if (days.length == 7) return 'Every day';
    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Weekdays';
    }
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => d < names.length ? names[d] : '$d').join(', ');
  }
}
