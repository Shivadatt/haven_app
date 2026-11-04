import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_core/haven_core.dart' show BlockedFailure;
import 'package:haven_models/haven_models.dart' show PairingRequestStatus;

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../core/utils/haven_time.dart';
import '../../data/pairing_models.dart';

/// The pairing requests this account is allowed to read.
///
/// The count in the subtitle is the count that was read, not a claim about the
/// family: the window is a page size, so the line says "read" out loud instead of
/// implying nothing else exists.
final class RequestsCard extends StatelessWidget {
  const RequestsCard({required this.board, this.withdrawalGap, super.key});

  final PairingBoard board;

  /// Shown only when a request is genuinely waiting on a child and the backend
  /// has said why it cannot be withdrawn from here.
  final BlockedFailure? withdrawalGap;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Pairing requests',
    subtitle: board.counted,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!board.hasLines)
          Text(
            'Nothing has been requested for this family yet. A pairing request '
            'appears here once a device starts to join.',
            style: HavenText.body,
          )
        else
          for (final PairingLine line in board.lines) ...[
            PairingRow(line),
            if (line != board.lines.last)
              const SizedBox(height: HavenSpacing.sm),
          ],
        if (withdrawalGap != null) ...[
          const SizedBox(height: HavenSpacing.md),
          BlockedNotice.fromFailure(withdrawalGap!),
        ],
      ],
    ),
  );
}

/// One request, in the order a parent reads it: who, what state, since when.
final class PairingRow extends StatelessWidget {
  const PairingRow(this.line, {super.key});

  final PairingLine line;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(line.childName, style: HavenText.body),
            Text(
              _timing(),
              style: HavenText.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      StatusChip(label: line.statusLabel, tone: _tone),
    ],
  );

  /// Only times the row itself carries. The backend set `expires_at`; this
  /// screen repeats it rather than computing a lifetime it was never told.
  String _timing() {
    final String asked = 'Requested ${havenTimeAgo(line.request.createdAt)}';
    if (!line.isWaiting) return asked;
    return '$asked — open until ${havenDay(line.request.expiresAt) ?? 'an unset time'}';
  }

  StatusTone get _tone {
    // `approved` is the one outcome a parent wanted; a declined, cancelled or
    // timed-out request is history, not a fault to fix.
    switch (line.request.requestStatus) {
      case PairingRequestStatus.approved:
        return StatusTone.good;
      case PairingRequestStatus.pendingChild:
        return StatusTone.warning;
      default:
        return StatusTone.neutral;
    }
  }
}
