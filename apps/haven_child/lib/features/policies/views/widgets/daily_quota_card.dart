import 'package:flutter/material.dart';
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/status_chip.dart';

/// Renders daily screen time quota allowances and honest telemetry states.
final class DailyQuotaCard extends StatelessWidget {
  const DailyQuotaCard({
    required this.configuredMinutes,
    required this.isNeutral,
    this.quota,
    this.isExactMidnight = false,
    super.key,
  });

  final int configuredMinutes;
  final bool isNeutral;
  final DailyQuotaEvaluation? quota;
  final bool isExactMidnight;

  static const String midnightNotice =
      'New day starting · Screen time usage unavailable at boundary';

  static const String unconfirmedNotice =
      'Daily screen time total is unconfirmed by device telemetry. '
      'Quota evaluation is unavailable.';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ChildSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Daily screen time', style: ChildText.headline),
                ),
                if (isNeutral)
                  const ChildStatusChip(
                    key: ValueKey('quota-unlimited-chip'),
                    label: 'Unlimited',
                    tone: StatusTone.neutral,
                  )
                else if (quota != null && quota!.isReached)
                  const ChildStatusChip(
                    key: ValueKey('quota-reached-chip'),
                    label: 'Limit reached',
                    tone: StatusTone.bad,
                  ),
              ],
            ),
            const SizedBox(height: ChildSpacing.md),
            if (isNeutral) ...[
              Text(
                'Neutral policy imposes no daily screen-time limit.',
                style: ChildText.body,
              ),
            ] else if (isExactMidnight) ...[
              Text(
                'Configured limit: ${_formatMinutes(configuredMinutes)}',
                style: ChildText.body,
              ),
              const SizedBox(height: ChildSpacing.sm),
              Text(midnightNotice, style: ChildText.caption),
            ] else if (quota == null ||
                quota!.isUnavailable ||
                quota!.usedMinutes == null) ...[
              Text(
                'Configured limit: ${_formatMinutes(configuredMinutes)}',
                style: ChildText.body,
              ),
              const SizedBox(height: ChildSpacing.sm),
              Text(unconfirmedNotice, style: ChildText.caption),
            ] else ...[
              Row(
                children: [
                  Text('Used today', style: ChildText.label),
                  const Spacer(),
                  Text(
                    _formatMinutes(quota!.usedMinutes!),
                    style: ChildText.body,
                  ),
                ],
              ),
              const SizedBox(height: ChildSpacing.xs),
              Row(
                children: [
                  Text('Remaining', style: ChildText.label),
                  const Spacer(),
                  Text(
                    _formatMinutes(quota!.remainingMinutes ?? 0),
                    style: ChildText.body,
                  ),
                ],
              ),
              const SizedBox(height: ChildSpacing.xs),
              Row(
                children: [
                  Text('Daily limit', style: ChildText.label),
                  const Spacer(),
                  Text(
                    _formatMinutes(configuredMinutes),
                    style: ChildText.body,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (remaining == 0) return '$hours hr';
    return '$hours hr $remaining min';
  }
}
