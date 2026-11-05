import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/dashboard_controller.dart';
import '../../data/dashboard_activity_item.dart';
import '../../data/dashboard_repository.dart';

/// Recent activities timeline displayed on the Parent Dashboard.
final class RecentActivitiesCard extends GetView<DashboardController> {
  const RecentActivitiesCard({required this.data, super.key});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Recent activities',
      subtitle: 'Timeline of events reported by devices in this family.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.recentActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: HavenSpacing.sm),
              child: Text(
                'No activities recorded yet. App use and location updates '
                'will appear here.',
                style: HavenText.body,
              ),
            )
          else ...[
            for (final item in data.recentActivities) ...[
              _ActivityRow(item),
              const Divider(height: HavenSpacing.md),
            ],
          ],
          HavenButton(
            label: 'See all reported activity',
            primary: false,
            onPressed: controller.goToActivity,
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(this.item);

  final DashboardActivityItem item;

  @override
  Widget build(BuildContext context) {
    final Color muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(item.icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: HavenSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: HavenText.body),
              Text(
                '${item.detail} · ${item.timeAgo}',
                style: HavenText.caption.copyWith(color: muted),
              ),
            ],
          ),
        ),
        if (item.isDemo) ...[
          const SizedBox(width: HavenSpacing.xs),
          const StatusChip(label: 'DEMO', tone: StatusTone.warning),
        ],
      ],
    );
  }
}
