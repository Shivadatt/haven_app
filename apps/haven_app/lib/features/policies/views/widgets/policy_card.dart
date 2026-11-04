import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart' show PolicyEnforcementStatus;

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../data/policies_models.dart';

/// The versions read for this family, newest write first.
///
/// Each row says what the device answered, and nothing more: a version written
/// by a parent is not a rule a phone is following.
final class PolicyCard extends StatelessWidget {
  const PolicyCard({required this.board, super.key});

  final PolicyBoard board;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Rule versions on record',
    subtitle: board.counted,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!board.hasLines)
          Text(
            'No rule version has been written for this family yet.',
            style: HavenText.body,
          )
        else ...[
          for (int i = 0; i < board.lines.length; i++) ...[
            if (i > 0) const SizedBox(height: HavenSpacing.md),
            PolicyRow(board.lines[i]),
          ],
          const SizedBox(height: HavenSpacing.sm),
          Text(
            board.enforcedLine,
            style: HavenText.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            board.newestLine,
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

/// One version: whose device, which number, when written, what came back.
final class PolicyRow extends StatelessWidget {
  const PolicyRow(this.line, {super.key});

  final PolicyLine line;

  @override
  Widget build(BuildContext context) {
    final Color muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final String? trouble = line.trouble;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                '${line.which} · ${line.whose}',
                style: HavenText.body,
              ),
            ),
            const SizedBox(width: HavenSpacing.sm),
            StatusChip(label: line.statusLabel, tone: _tone(line)),
          ],
        ),
        Text(
          '${line.written} · ${line.outcome}',
          style: HavenText.caption.copyWith(color: muted),
        ),
        if (line.answered != null)
          Text(line.answered!, style: HavenText.caption.copyWith(color: muted)),
        if (trouble != null)
          Text(
            'The device said: $trouble',
            style: HavenText.caption.copyWith(color: muted),
          ),
      ],
    );
  }

  /// `enforced` is the only state a device reported as done, so it is the only
  /// one that reads green. Everything else is a wait, a refusal or a defect.
  static StatusTone _tone(PolicyLine line) => switch (line.policy.statusEnum) {
    PolicyEnforcementStatus.enforced => StatusTone.good,
    PolicyEnforcementStatus.failed => StatusTone.bad,
    PolicyEnforcementStatus.unsupported => StatusTone.warning,
    _ => StatusTone.neutral,
  };
}

/// The two questions this screen cannot answer, stated before a parent asks.
final class PolicyLimitsCard extends StatelessWidget {
  const PolicyLimitsCard({required this.board, super.key});

  final PolicyBoard board;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'What these versions do not tell you',
    subtitle:
        'A row here proves a version was written, not that it is in force.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Haven can read the version numbers kept for this family and what each '
          'device said about them. It cannot yet show what the rules themselves '
          'say, and nothing here can be changed from this app.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        BlockedNotice.fromFailure(board.ruleShapeGap),
        const SizedBox(height: HavenSpacing.md),
        BlockedNotice.fromFailure(board.writeGap),
      ],
    ),
  );
}
