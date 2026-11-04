import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../data/location_models.dart';

/// The reported places, newest first, with the two boundaries the read carries.
///
/// [showsCoordinates] comes from the controller rather than a widget field so the
/// reveal is one decision on one screen, and the page can say what is hidden.
final class FixCard extends StatelessWidget {
  const FixCard({
    required this.board,
    required this.showsCoordinates,
    super.key,
  });

  final FixBoard board;
  final bool showsCoordinates;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Places the device reported',
    subtitle: board.counted,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!board.hasLines)
          Text(
            'No device has reported a place for this family yet.',
            style: HavenText.body,
          )
        else
          for (int i = 0; i < board.lines.length; i++) ...[
            if (i > 0) const SizedBox(height: HavenSpacing.md),
            FixRow(board.lines[i], showsCoordinates: showsCoordinates),
          ],
        if (board.deviceGap != null) ...[
          const SizedBox(height: HavenSpacing.md),
          BlockedNotice.fromFailure(board.deviceGap!),
        ],
      ],
    ),
  );
}

/// One fix: when it was taken, how wide the device says it is, and whose phone.
final class FixRow extends StatelessWidget {
  const FixRow(this.line, {required this.showsCoordinates, super.key});

  final FixLine line;
  final bool showsCoordinates;

  @override
  Widget build(BuildContext context) {
    final Color muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(line.whose, style: HavenText.body),
        Text(
          '${line.recorded} — ${line.accuracy}',
          style: HavenText.caption.copyWith(color: muted),
        ),
        Text(line.delay, style: HavenText.caption.copyWith(color: muted)),
        if (showsCoordinates)
          Text(
            '${line.coordinates} · ${line.source}',
            style: HavenText.caption.copyWith(color: muted),
          ),
      ],
    );
  }
}

/// What the list cannot say, stated before a parent has to ask.
final class LocationLimitsCard extends StatelessWidget {
  const LocationLimitsCard({required this.board, super.key});

  final FixBoard board;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'What these places are not',
    subtitle: 'A row is a report, not a live view of a child.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Haven shows the readings a device chose to send, with the accuracy '
          'figure that came with each one. It does not show a map, it does not '
          'name a street or a building, and it does not know where a device is '
          'between reports.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        BlockedNotice.fromFailure(board.presenceGap),
      ],
    ),
  );
}
