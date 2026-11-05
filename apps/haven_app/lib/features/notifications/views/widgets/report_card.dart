import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart' show AlertSeverity;

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/notifications_controller.dart';
import '../../data/alerts_models.dart';
import 'alert_detail_dialog.dart';
import 'alert_filter_chips.dart';

export 'report_limits_card.dart';

/// The reports read for this family, newest first, each in the backend's words.
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
        if (board.canManage) ...[
          const AlertFilterChips(),
          const SizedBox(height: HavenSpacing.md),
        ],
        if (!board.hasLines)
          Text(
            'Nothing has been reported about this family yet.',
            style: HavenText.body,
          )
        else ...[
          _AlertLinesList(board: board),
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

class _AlertLinesList extends StatelessWidget {
  const _AlertLinesList({required this.board});

  final AlertBoard board;

  @override
  Widget build(BuildContext context) {
    if (board.canManage && Get.isRegistered<NotificationsController>()) {
      final controller = Get.find<NotificationsController>();
      return Obx(() {
        final lines = controller.filteredLines;
        if (lines.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: HavenSpacing.sm),
            child: Text('No reports in this category.', style: HavenText.body),
          );
        }
        return Column(
          children: [
            for (int i = 0; i < lines.length; i++) ...[
              if (i > 0) const SizedBox(height: HavenSpacing.md),
              ReportRow(
                lines[i],
                onTap: () => AlertDetailDialog.show(context, lines[i], true),
              ),
            ],
          ],
        );
      });
    }

    return Column(
      children: [
        for (int i = 0; i < board.lines.length; i++) ...[
          if (i > 0) const SizedBox(height: HavenSpacing.md),
          ReportRow(board.lines[i]),
        ],
      ],
    );
  }
}

/// One report: the sentence the backend wrote, the row's own type and severity,
/// and whether the record marks it answered.
final class ReportRow extends StatelessWidget {
  const ReportRow(this.line, {this.onTap, super.key});

  final AlertLine line;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(line.said, style: HavenText.body)),
            const SizedBox(width: HavenSpacing.sm),
            if (line.isDemo) ...[
              const StatusChip(label: 'DEMO', tone: StatusTone.warning),
              const SizedBox(width: HavenSpacing.xs),
            ],
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

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: content,
    );
  }

  static StatusTone _tone(AlertLine line) => switch (line.alert.alertSeverity) {
    AlertSeverity.critical => StatusTone.bad,
    AlertSeverity.warning => StatusTone.warning,
    _ => StatusTone.neutral,
  };
}
