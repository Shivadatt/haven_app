import 'package:flutter/material.dart';

import '../../../../app/theme/child_colors.dart';
import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../core/native/usage_envelope_models.dart';
import 'daily_screen_time_card.dart';

/// Card displaying per-application foreground usage records.
final class AppUsageListCard extends StatelessWidget {
  const AppUsageListCard({
    required this.appRecords,
    super.key,
  });

  final List<UsageAppRecord> appRecords;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (appRecords.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChildRadius.md),
          side: BorderSide(color: colorScheme.outline.withAlpha(80)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ChildSpacing.md),
          child: Center(
            child: Text(
              'No application usage recorded today.',
              style: ChildText.body.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
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
                  Icons.apps_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: ChildSpacing.sm),
                Expanded(child: Text('App Usage', style: ChildText.headline)),
              ],
            ),
            const SizedBox(height: ChildSpacing.sm),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appRecords.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: colorScheme.outline.withAlpha(40),
              ),
              itemBuilder: (context, index) {
                final record = appRecords[index];
                return _AppRecordRow(
                  key: Key(record.packageName),
                  record: record,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

final class _AppRecordRow extends StatelessWidget {
  const _AppRecordRow({required this.record, super.key});

  final UsageAppRecord record;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final durationStr = DailyScreenTimeCard.formatDuration(record.foregroundDuration);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ChildSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(ChildRadius.sm),
            ),
            child: Icon(
              record.isSystemApp ? Icons.android_outlined : Icons.smartphone_outlined,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: ChildSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.packageName,
                  style: ChildText.label.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (record.isSystemApp)
                  Text(
                    'System App',
                    style: ChildText.caption.copyWith(
                      color: ChildColors.blocked,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: ChildSpacing.sm),
          Semantics(
            label: '${record.packageName}: $durationStr',
            excludeSemantics: true,
            child: Text(
              durationStr,
              style: ChildText.label.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
