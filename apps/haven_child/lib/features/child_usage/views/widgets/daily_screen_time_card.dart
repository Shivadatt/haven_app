import 'package:flutter/material.dart';

import '../../../../app/theme/child_colors.dart';
import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../domain/usage_freshness_status.dart';

/// Card presenting today's total screen time and data freshness status.
final class DailyScreenTimeCard extends StatelessWidget {
  const DailyScreenTimeCard({
    required this.totalDuration,
    this.freshness,
    super.key,
  });

  final Duration totalDuration;
  final UsageFreshnessStatus? freshness;

  static String formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedTime = formatDuration(totalDuration);

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChildRadius.md),
        side: BorderSide(color: colorScheme.outline.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ChildSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: ChildSpacing.sm),
                Expanded(
                  child: Text(
                    "Today's Screen Time",
                    style: ChildText.headline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ChildSpacing.sm),
            Semantics(
              label: "Today's total screen time: $formattedTime",
              excludeSemantics: true,
              child: Text(
                formattedTime,
                style: ChildText.largeTitle.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: ChildSpacing.xs),
            Text(
              'Total foreground device use today',
              style: ChildText.caption.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (freshness == UsageFreshnessStatus.delayed) ...[
              const SizedBox(height: ChildSpacing.sm),
              _FreshnessNotice(
                icon: Icons.info_outline,
                message: 'Usage data may be delayed due to Android system batching.',
                color: ChildColors.warning,
              ),
            ] else if (freshness == UsageFreshnessStatus.empty && totalDuration == Duration.zero) ...[
              const SizedBox(height: ChildSpacing.sm),
              _FreshnessNotice(
                icon: Icons.check_circle_outline,
                message: 'No device activity recorded yet today.',
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _FreshnessNotice extends StatelessWidget {
  const _FreshnessNotice({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ChildSpacing.sm,
        vertical: ChildSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(ChildRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: ChildSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: ChildText.caption.copyWith(
                color: color,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
