import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart' show CommandStatus;

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../data/commands_models.dart';

/// The instructions read for this family, newest first, each with the state the
/// row carries.
///
/// The subtitle counts rows *read*: [CommandBoard.window] is a page size and no
/// captured retention rule makes it a history.
final class CommandCard extends StatelessWidget {
  const CommandCard({required this.board, super.key});

  final CommandBoard board;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Instructions on record',
    subtitle: board.counted,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!board.hasLines)
          Text(
            'No instruction has been written for this family yet.',
            style: HavenText.body,
          )
        else ...[
          for (int i = 0; i < board.lines.length; i++) ...[
            if (i > 0) const SizedBox(height: HavenSpacing.md),
            CommandRow(board.lines[i]),
          ],
          const SizedBox(height: HavenSpacing.sm),
          Text(
            board.answeredLine,
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

/// One row: what was asked of which device, how far it got, and what came back.
final class CommandRow extends StatelessWidget {
  const CommandRow(this.line, {super.key});

  final CommandLine line;

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
            Expanded(child: Text(line.what, style: HavenText.body)),
            const SizedBox(width: HavenSpacing.sm),
            StatusChip(label: line.statusLabel, tone: _tone(line)),
          ],
        ),
        Text(
          '${line.whose} · ${line.when}',
          style: HavenText.caption.copyWith(color: muted),
        ),
        Text(
          [
            line.state,
            line.answered,
            line.tries,
          ].whereType<String>().join(' · '),
          style: HavenText.caption.copyWith(color: muted),
        ),
        if (trouble != null)
          Text(
            'The device said: $trouble',
            style: HavenText.caption.copyWith(color: muted),
          ),
      ],
    );
  }

  /// The colour follows the row's state, never a guess about the device: an
  /// answer that came back is good or bad, and everything else is a wait.
  static StatusTone _tone(CommandLine line) =>
      switch (line.command.commandStatus) {
        CommandStatus.succeeded => StatusTone.good,
        CommandStatus.failed => StatusTone.bad,
        CommandStatus.expired => StatusTone.warning,
        _ => StatusTone.neutral,
      };
}

/// Why there is no way to ask a device for anything from here.
final class CommandLimitsCard extends StatelessWidget {
  const CommandLimitsCard({required this.board, super.key});

  final CommandBoard board;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'What you can do with this list',
    subtitle: 'Read it. Nothing on this screen can change it.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'An instruction only means something once a device answers it. This '
          'build can read the rows a device has already been given, and it can '
          'show whether an answer came back — but it has no way to write a row, '
          'no way to cancel one, and no way to mark one as done.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        BlockedNotice.fromFailure(board.writeGap),
      ],
    ),
  );
}
