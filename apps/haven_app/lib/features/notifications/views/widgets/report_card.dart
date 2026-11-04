import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart' show AlertSeverity;

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../data/alerts_models.dart';

/// The reports read for this family, newest first, each in the backend's words.
///
/// [AlertBoard.window] is a page size, so the subtitle counts rows read rather
/// than claiming a complete history.
final class ReportListCard extends StatelessWidget {
  const ReportListCard({required this.board, super.key});

  final AlertBoard board;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'What the backend reported',
    subtitle: board.counted,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!board.hasLines)
          Text(
            'Nothing has been reported about this family yet.',
            style: HavenText.body,
          )
        else ...[
          for (int i = 0; i < board.lines.length; i++) ...[
            if (i > 0) const SizedBox(height: HavenSpacing.md),
            ReportRow(board.lines[i]),
          ],
          const SizedBox(height: HavenSpacing.sm),
          for (final String line in <String>[
            board.answeredLine,
            board.severityLine,
          ])
            Text(
              line,
              style: HavenText.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
        if (board.deviceGap != null) ...[
          const SizedBox(height: HavenSpacing.md),
          BlockedNotice.fromFailure(board.deviceGap!),
        ],
      ],
    ),
  );
}

/// One report: the sentence the backend wrote, the row's own type and severity,
/// and whether the record marks it answered.
final class ReportRow extends StatelessWidget {
  const ReportRow(this.line, {super.key});

  final AlertLine line;

  @override
  Widget build(BuildContext context) {
    final Color muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(line.said, style: HavenText.body)),
            const SizedBox(width: HavenSpacing.sm),
            StatusChip(label: line.severityLabel, tone: _tone(line)),
          ],
        ),
        Text(
          '${line.whose} · ${line.when}',
          style: HavenText.caption.copyWith(color: muted),
        ),
        Text(
          [line.kind, line.answer, line.payloadLine].join(' · '),
          style: HavenText.caption.copyWith(color: muted),
        ),
      ],
    );
  }

  /// The colour follows the row's severity, and an unrecognised value stays
  /// neutral instead of being promoted to an alarm.
  static StatusTone _tone(AlertLine line) => switch (line.alert.alertSeverity) {
    AlertSeverity.critical => StatusTone.bad,
    AlertSeverity.warning => StatusTone.warning,
    _ => StatusTone.neutral,
  };
}

/// Why this screen is a list and not an inbox.
final class ReportLimitsCard extends StatelessWidget {
  const ReportLimitsCard({
    required this.board,
    required this.canRegister,
    required this.onOpenSettings,
    super.key,
  });

  final AlertBoard board;

  /// What the delivery seam answers. False in this build, and the sentence below
  /// is what a parent sees because of it.
  final bool canRegister;

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'What you can do with this list',
    subtitle:
        'Read it. Nothing here can be marked, and nothing arrives on its own.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!canRegister)
          Text(
            'This is a read of the reports, not a delivery: the list shows what '
            'the backend had written when the screen read it. Nothing has '
            'registered this phone to be sent a notification about a new one.',
            style: HavenText.body,
          ),
        if (!canRegister) const SizedBox(height: HavenSpacing.md),
        BlockedNotice.fromFailure(board.deliveryGap),
        const SizedBox(height: HavenSpacing.md),
        BlockedNotice.fromFailure(board.ackGap),
        const SizedBox(height: HavenSpacing.md),
        Text(
          'Whether this phone is allowed to show notifications is asked on the '
          'settings screen, which owns that question.',
          style: HavenText.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: HavenSpacing.sm),
        HavenButton(
          label: 'Open settings',
          primary: false,
          onPressed: onOpenSettings,
        ),
      ],
    ),
  );
}
