import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart' show SessionStatus;

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../data/sessions_models.dart';

/// The session records read for this family, newest request first.
///
/// [SessionBoard.window] is a page size, so the subtitle counts rows read rather
/// than claiming a history.
final class SessionListCard extends StatelessWidget {
  const SessionListCard({required this.board, this.onOpen, super.key});

  final SessionBoard board;

  /// Opens one record. Navigation is the only action here, and it works on a row
  /// the backend returned.
  final void Function(String sessionId)? onOpen;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Sessions asked for',
    subtitle: board.counted,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!board.hasLines)
          Text(
            'No session has been asked for in this family yet.',
            style: HavenText.body,
          )
        else ...[
          for (int i = 0; i < board.lines.length; i++) ...[
            if (i > 0) const SizedBox(height: HavenSpacing.md),
            SessionRow(board.lines[i], onOpen: onOpen),
          ],
          const SizedBox(height: HavenSpacing.sm),
          Text(
            board.liveLine,
            style: HavenText.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            board.consentLine,
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

/// One record: what was asked, whether consent is on the row, and where the
/// lifecycle stands.
final class SessionRow extends StatelessWidget {
  const SessionRow(this.line, {this.onOpen, super.key});

  final SessionLine line;
  final void Function(String sessionId)? onOpen;

  @override
  Widget build(BuildContext context) {
    final Color muted = Theme.of(context).colorScheme.onSurfaceVariant;
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
          '${line.whose} · ${line.consent}',
          style: HavenText.caption.copyWith(color: muted),
        ),
        Text(line.trail, style: HavenText.caption.copyWith(color: muted)),
        if (line.whyClosed != null)
          Text(
            'The record said: ${line.whyClosed}',
            style: HavenText.caption.copyWith(color: muted),
          ),
        if (onOpen != null)
          Padding(
            padding: const EdgeInsets.only(top: HavenSpacing.xs),
            child: HavenButton(
              label: 'Open this record',
              primary: false,
              onPressed: () => onOpen!.call(line.session.id),
            ),
          ),
      ],
    );
  }

  /// The colour follows the row, not a guess about the phone — and a row that is
  /// open with no consent mark is flagged rather than shown as ordinary.
  static StatusTone _tone(SessionLine line) =>
      switch (line.session.sessionStatus) {
        SessionStatus.active =>
          line.liveWithoutConsent ? StatusTone.bad : StatusTone.good,
        SessionStatus.failed => StatusTone.bad,
        SessionStatus.expired => StatusTone.warning,
        _ => StatusTone.neutral,
      };
}

/// Why this screen lists sessions and does not start one.
final class SessionLimitsCard extends StatelessWidget {
  const SessionLimitsCard({required this.board, super.key});

  final SessionBoard board;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'What you can do with this list',
    subtitle: 'Read it, and open a record. Nothing here can start a session.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A session is a request one parent makes and the child\'s side answers. '
          'This build can read where such a request stands, and it can show the '
          'consent mark on the row, but it has no way to ask for a session, to '
          'answer one, or to retire one that went stale.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        BlockedNotice.fromFailure(board.startGap),
        const SizedBox(height: HavenSpacing.md),
        BlockedNotice.fromFailure(board.mediaGap),
      ],
    ),
  );
}
