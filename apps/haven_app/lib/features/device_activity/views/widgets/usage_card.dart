import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../data/activity_models.dart';

/// The days this family may read, with the owner left unnamed until the device
/// table can be reached.
///
/// The subtitle counts rows *read*, not days that exist: [UsageBoard.window] is a
/// page size, and saying otherwise would be a statistic this build cannot support.
final class UsageCard extends StatelessWidget {
  const UsageCard({required this.board, super.key});

  final UsageBoard board;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'App use, as reported',
    subtitle: board.counted,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!board.hasLines)
          Text(
            'No device has reported a day of use for this family yet.',
            style: HavenText.body,
          )
        else
          for (int i = 0; i < board.lines.length; i++) ...[
            if (i > 0) const SizedBox(height: HavenSpacing.md),
            UsageRow(board.lines[i]),
          ],
        if (board.deviceGap != null) ...[
          const SizedBox(height: HavenSpacing.md),
          BlockedNotice.fromFailure(board.deviceGap!),
        ],
      ],
    ),
  );
}

/// One row: which app, how long, on which day, on whose phone.
final class UsageRow extends StatelessWidget {
  const UsageRow(this.line, {super.key});

  final UsageLine line;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(line.appLabel, style: HavenText.body)),
          if (line.isDemo) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              margin: const EdgeInsets.only(right: HavenSpacing.xs),
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
          Text(line.duration, style: HavenText.label),
        ],
      ),
      Text(
        '${line.day} — ${line.whose}',
        style: HavenText.caption.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      Text(
        line.lastUsed,
        style: HavenText.caption.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

/// What the list is not: not a live view, not a score, not the whole history.
final class UsageLimitsCard extends StatelessWidget {
  const UsageLimitsCard({super.key});

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'What this list is not',
    subtitle: 'Reading these rows is not the same as watching a phone live.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Haven shows what the device chose to report, per app and per day. It '
          'does not show what was open a moment ago, it does not score or rank '
          'that use, and the totals here cover only the rows this screen was able '
          'to read.',
          style: HavenText.body,
        ),
      ],
    ),
  );
}
