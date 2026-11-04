import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../data/session_detail_models.dart';
import '../../data/sessions_models.dart' show SessionLine;

/// One session record in full, with the signalling rows that were in the buffer.
final class SessionDetailCard extends StatelessWidget {
  const SessionDetailCard({required this.detail, super.key});

  final SessionDetail detail;

  @override
  Widget build(BuildContext context) {
    final Color muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final SessionLine line = detail.line;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'What the record says',
          subtitle: line.whose,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(line.what, style: HavenText.body)),
                  const SizedBox(width: HavenSpacing.sm),
                  StatusChip(
                    label: line.statusLabel,
                    tone: line.liveWithoutConsent
                        ? StatusTone.bad
                        : StatusTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: HavenSpacing.sm),
              Text(line.state, style: HavenText.body),
              const SizedBox(height: HavenSpacing.sm),
              Text(line.consent, style: HavenText.body),
              const SizedBox(height: HavenSpacing.sm),
              Text(line.trail, style: HavenText.caption.copyWith(color: muted)),
              if (line.whyClosed != null)
                Text(
                  'The record said: ${line.whyClosed}',
                  style: HavenText.caption.copyWith(color: muted),
                ),
              if (detail.deviceGap != null) ...[
                const SizedBox(height: HavenSpacing.md),
                BlockedNotice.fromFailure(detail.deviceGap!),
              ],
            ],
          ),
        ),
        const SizedBox(height: HavenSpacing.md),
        SectionCard(
          title: 'Signalling rows',
          subtitle: detail.counted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!detail.hasSignals)
                Text(
                  'The read came back with nothing in the buffer.',
                  style: HavenText.body,
                )
              else ...[
                for (int i = 0; i < detail.signals.length; i++) ...[
                  if (i > 0) const SizedBox(height: HavenSpacing.sm),
                  SignalRow(detail.signals[i]),
                ],
                const SizedBox(height: HavenSpacing.sm),
                Text(
                  detail.bufferLine,
                  style: HavenText.caption.copyWith(color: muted),
                ),
              ],
              const SizedBox(height: HavenSpacing.md),
              BlockedNotice.fromFailure(detail.signalGap),
            ],
          ),
        ),
      ],
    );
  }
}

/// One transport row, described by its own columns and nothing more.
final class SignalRow extends StatelessWidget {
  const SignalRow(this.signal, {super.key});

  final SignalLine signal;

  @override
  Widget build(BuildContext context) => Text(
    signal.line,
    style: HavenText.caption.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

/// Why this screen cannot show or hear anything, stated once.
final class SessionMediaCard extends StatelessWidget {
  const SessionMediaCard({
    required this.detail,
    required this.carriesMedia,
    super.key,
  });

  final SessionDetail detail;

  /// What the peer answers. In this build it is always false, and the sentence
  /// below is what a parent sees because of it.
  final bool carriesMedia;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'The connection itself',
    subtitle: 'This screen opens nothing.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(detail.stateLine, style: HavenText.body),
        if (!carriesMedia) ...[
          const SizedBox(height: HavenSpacing.sm),
          Text(
            'Nothing in this build carries sound or picture, so a session that '
            'the record says is running is shown here as a record, not as a '
            'view of the phone.',
            style: HavenText.body,
          ),
        ],
        const SizedBox(height: HavenSpacing.md),
        BlockedNotice.fromFailure(detail.mediaGap),
      ],
    ),
  );
}
