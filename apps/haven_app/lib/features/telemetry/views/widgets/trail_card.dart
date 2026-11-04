import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/telemetry_controller.dart';
import '../../data/telemetry_models.dart';

/// The family's trail, mounted inside the device screen.
///
/// Two refusals ride along with the rows — whether a device is online, and whose
/// device an entry came from — because both are questions this exact card would
/// otherwise be asked to answer.
final class TelemetryCard extends GetView<TelemetryController> {
  const TelemetryCard({super.key});

  @override
  Widget build(BuildContext context) => Obx(
    () => StateView<TelemetryBoard?>(
      isLoading: controller.isLoading.value,
      result: controller.board.value,
      onRetry: controller.load,
      empty: () => const _TrailUnreadable(),
      onData: (BuildContext context, TelemetryBoard? board) => _Trail(board!),
    ),
  );
}

class _Trail extends StatelessWidget {
  const _Trail(this.board);

  final TelemetryBoard board;

  @override
  Widget build(BuildContext context) {
    final Color muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return SectionCard(
      title: 'What the backend recorded',
      subtitle: board.counted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!board.hasLines)
            Text(
              'Nothing has been recorded for this family that this account is '
              'allowed to see.',
              style: HavenText.body,
            )
          else
            for (int i = 0; i < board.lines.length; i++) ...[
              if (i > 0) const SizedBox(height: HavenSpacing.sm),
              AuditRow(board.lines[i]),
            ],
          const SizedBox(height: HavenSpacing.md),
          BlockedNotice.fromFailure(board.offlineGap),
          if (board.deviceGap != null) ...[
            const SizedBox(height: HavenSpacing.sm),
            BlockedNotice.fromFailure(board.deviceGap!),
          ],
          const SizedBox(height: HavenSpacing.sm),
          Text(
            'This is a read of the log, not a live view: it shows the newest '
            'entries at the moment it was opened.',
            style: HavenText.caption.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

/// One entry, in the backend's own words.
final class AuditRow extends StatelessWidget {
  const AuditRow(this.line, {super.key});

  final AuditLine line;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(line.what, style: HavenText.body),
      Text(
        [
          line.when,
          line.about,
          if (line.whose != null) 'on ${line.whose}',
          line.notes,
        ].join(' · '),
        style: HavenText.caption.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _TrailUnreadable extends StatelessWidget {
  const _TrailUnreadable();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'No trail to read',
    child: Text(
      'An entry belongs to a family. With no family for this account, there is '
      'nothing for this card to show.',
      style: HavenText.body,
    ),
  );
}
