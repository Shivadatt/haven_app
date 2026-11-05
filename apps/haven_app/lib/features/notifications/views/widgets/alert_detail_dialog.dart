import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart' show AlertSeverity;

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/notifications_controller.dart';
import '../../data/alerts_models.dart';

/// Detail dialog for an individual safety alert report.
class AlertDetailDialog extends StatelessWidget {
  const AlertDetailDialog({
    required this.line,
    required this.canManage,
    super.key,
  });

  final AlertLine line;
  final bool canManage;

  static void show(BuildContext context, AlertLine line, bool canManage) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDetailDialog(line: line, canManage: canManage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final NotificationsController controller =
        Get.find<NotificationsController>();
    final Color muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(line.said, style: HavenText.title)),
          if (line.isDemo) ...[
            const SizedBox(width: HavenSpacing.xs),
            const StatusChip(label: 'DEMO', tone: StatusTone.warning),
          ],
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusChip(
              label: line.severityLabel,
              tone: _tone(line.alert.alertSeverity),
            ),
            const SizedBox(height: HavenSpacing.md),
            Text('Device: ${line.whose}', style: HavenText.body),
            const SizedBox(height: HavenSpacing.xs),
            Text(line.when, style: HavenText.caption.copyWith(color: muted)),
            const SizedBox(height: HavenSpacing.xs),
            Text(line.kind, style: HavenText.caption.copyWith(color: muted)),
            const SizedBox(height: HavenSpacing.sm),
            Text(
              line.isRead ? 'Status: Answered in record' : 'Status: Unread',
              style: HavenText.label,
            ),
            if (line.alert.payload.isNotEmpty) ...[
              const SizedBox(height: HavenSpacing.md),
              Text('Details stored with event:', style: HavenText.caption),
              const SizedBox(height: HavenSpacing.xs),
              for (final entry in line.alert.payload.entries)
                Text('${entry.key}: ${entry.value}', style: HavenText.caption),
            ],
          ],
        ),
      ),
      actions: [
        if (canManage) ...[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDelete(context, controller);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              controller.toggleRead(line);
              Navigator.of(context).pop();
            },
            child: Text(line.isRead ? 'Mark as unread' : 'Mark as read'),
          ),
        ],
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _confirmDelete(
    BuildContext context,
    NotificationsController controller,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete alert report?'),
        content: const Text(
          'This action removes this safety report from your local records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteAlert(line.alert.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  static StatusTone _tone(AlertSeverity? severity) => switch (severity) {
    AlertSeverity.critical => StatusTone.bad,
    AlertSeverity.warning => StatusTone.warning,
    _ => StatusTone.neutral,
  };
}
