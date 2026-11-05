import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../data/activity_models.dart';

/// Timeline card displaying chronological events (app usage, safe zones, battery).
final class ActivityTimelineCard extends StatelessWidget {
  const ActivityTimelineCard({required this.board, super.key});

  final UsageBoard board;

  @override
  Widget build(BuildContext context) {
    if (!board.isOffline && !board.hasEvents) {
      return const SizedBox.shrink();
    }

    return SectionCard(
      title: 'Activity Timeline',
      subtitle: '${board.events.length} chronological events recorded',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (board.events.isEmpty)
            Text(
              'No events recorded yet.',
              style: HavenText.body,
            )
          else
            for (int i = 0; i < board.events.length; i++) ...[
              if (i > 0) const Divider(height: HavenSpacing.md),
              _TimelineEventRow(event: board.events[i]),
            ],
        ],
      ),
    );
  }
}

class _TimelineEventRow extends StatelessWidget {
  const _TimelineEventRow({required this.event});

  final TimelineActivityEvent event;

  IconData _iconFor(String category) {
    switch (category) {
      case 'app_usage':
        return Icons.apps;
      case 'geofence':
        return Icons.location_on_outlined;
      case 'battery':
        return Icons.battery_alert_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorFor(BuildContext context, String category) {
    switch (category) {
      case 'geofence':
        return Colors.teal;
      case 'battery':
        return Colors.orange;
      case 'app_usage':
        return Theme.of(context).colorScheme.primary;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(context, event.category);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(_iconFor(event.category), size: 16, color: color),
        ),
        const SizedBox(width: HavenSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: HavenText.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (event.isDemo)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DEMO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                event.subtitle,
                style: HavenText.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
