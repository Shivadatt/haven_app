import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_core/haven_core.dart' show HavenFailure;
import 'package:haven_models/haven_models.dart' show SafetyAlert, AlertSeverity;

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../core/utils/haven_time.dart';
import '../../data/dashboard_repository.dart';

/// The most recent reports the backend has about this family.
///
/// A failed read is shown as a failure, in this section's own space. It does
/// not blank the dashboard and it is never presented as an empty list, which a
/// parent would read as "nothing is wrong".
class AttentionCard extends StatelessWidget {
  const AttentionCard({super.key, required this.data, this.onOpenAll});

  final DashboardData data;

  /// Opens the reports screen, which reads the same table with a wider window.
  final VoidCallback? onOpenAll;

  @override
  Widget build(BuildContext context) {
    final int unread = data.unreadAlertsCount;
    return SectionCard(
      title: unread > 0 ? 'Needs attention ($unread new)' : 'Needs attention',
      subtitle: _subtitle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _body(context),
          if (onOpenAll != null) ...[
            const SizedBox(height: HavenSpacing.sm),
            HavenButton(
              label: 'Open the full list',
              primary: false,
              onPressed: onOpenAll,
            ),
          ],
        ],
      ),
    );
  }

  /// Only counts what was read: a window of "0 most recent reports" next to a
  /// failure would claim the read happened.
  String? _subtitle() {
    if (data.alertsFailure != null || !data.hasAlerts) return null;
    return 'The ${data.alerts.length} most recent reports from the backend, '
        'newest first.';
  }

  Widget _body(BuildContext context) {
    final HavenFailure? failure = data.alertsFailure;
    if (failure != null) {
      return Text(
        'Haven could not read the reports: ${failure.message}',
        style: HavenText.body,
      );
    }
    if (!data.hasAlerts) {
      return Text(
        'Nothing has been reported about this family yet.',
        style: HavenText.body,
      );
    }
    return Column(
      children: [for (final SafetyAlert alert in data.alerts) AlertRow(alert)],
    );
  }
}

class AlertRow extends StatelessWidget {
  const AlertRow(this.alert, {super.key});

  final SafetyAlert alert;

  @override
  Widget build(BuildContext context) {
    final AlertSeverity? severity = alert.alertSeverity;
    return Padding(
      padding: const EdgeInsets.only(bottom: HavenSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.message, style: HavenText.body),
                Text(havenTimeAgo(alert.createdAt), style: HavenText.caption),
              ],
            ),
          ),
          const SizedBox(width: HavenSpacing.md),
          if (alert.id.startsWith('demo_')) ...[
            const StatusChip(label: 'DEMO', tone: StatusTone.warning),
            const SizedBox(width: HavenSpacing.xs),
          ],
          StatusChip(label: _label(severity), tone: _tone(severity)),
        ],
      ),
    );
  }

  static String _label(AlertSeverity? severity) =>
      severity?.label ?? 'No severity recorded';

  static StatusTone _tone(AlertSeverity? severity) => switch (severity) {
    AlertSeverity.critical => StatusTone.bad,
    AlertSeverity.warning => StatusTone.warning,
    AlertSeverity.info => StatusTone.neutral,
    null => StatusTone.neutral,
  };
}
