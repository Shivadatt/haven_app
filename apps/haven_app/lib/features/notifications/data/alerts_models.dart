import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// One `safety_alerts` row: what the backend chose to tell a parent, in the
/// backend's own words.
///
/// `message` is free text of 1..300 characters (`A3-staging-load-v1.sql:488`) and
/// is shown exactly as it arrived. `type` and `severity` are bound by CHECKs
/// (`:491`, `:490`), so a value outside their lists is echoed rather than sorted
/// into a category Haven invented, and `payload` is only proven to be a JSON
/// object (`:489`) — its keys are counted, never printed.
final class AlertLine {
  const AlertLine(this.alert, {this.deviceName});

  final SafetyAlert alert;

  /// The device the alert names, when the device lane could be read.
  final String? deviceName;

  String get whose => deviceName ?? 'a device this build cannot name';

  /// The backend's own sentence. Nothing here rewrites it into an interpretation.
  String get said => alert.message;

  String get kind {
    final AlertType? type = alert.alertType;
    if (type == null) {
      return 'Recorded as something this build does not recognise (${alert.type})';
    }
    return 'Recorded as: ${type.label}';
  }

  String get severityLabel => alert.alertSeverity?.label ?? 'Unrecognised';

  /// `acknowledged_at` is written by a service role alone (`sql:1102-1103`), so an
  /// answer on a row is not something this screen did.
  String get answer => alert.acknowledgedAt == null
      ? 'no one has answered it in the record'
      : 'answered ${alert.acknowledgedAt!.toUtc().toIso8601String()}';

  String get when => 'at ${alert.createdAt.toUtc().toIso8601String()}';

  int get notes => alert.payload.length;

  String get payloadLine => notes == 0
      ? 'nothing else was stored with it'
      : '$notes ${notes == 1 ? 'item' : 'items'} stored with it, not shown here';
}

/// The reports this family may read, and the two lanes beside them.
final class AlertBoard {
  const AlertBoard({
    required this.familyId,
    required this.lines,
    required this.ackGap,
    required this.deliveryGap,
    this.deviceGap,
  });

  final String familyId;
  final List<AlertLine> lines;

  /// Acknowledging an alert is a column write that only a service role holds, so
  /// a "mark as read" control would be refused the moment it was pressed.
  final BlockedFailure ackGap;

  /// Delivery. The token a phone would hand over has nowhere to go: no captured
  /// table holds one, and the migration that would is not approved.
  final BlockedFailure deliveryGap;

  /// The refusal that would otherwise name each alert's device.
  final BlockedFailure? deviceGap;

  bool get hasLines => lines.isNotEmpty;

  /// A page size, not the whole log. Splitting `safety_alerts` into events and
  /// notifications was explicitly left out of Stage 1 (`docs/stage1/03-data-model.md:118`).
  static const int window = 25;

  String get counted =>
      '${lines.length} ${lines.length == 1 ? 'report' : 'reports'} read — the '
      'newest $window rows the backend would give for this family.';

  int get answeredCount =>
      lines.where((AlertLine line) => line.alert.isAcknowledged).length;

  String get answeredLine =>
      '$answeredCount of ${lines.length} are marked as answered in the record. '
      'That mark is not something this screen can give a row.';

  /// The count that decides whether the screen needs the "needs attention now"
  /// sentence at all, so the copy is driven by the rows rather than by a mood.
  int get criticalCount => lines
      .where(
        (AlertLine line) => line.alert.alertSeverity == AlertSeverity.critical,
      )
      .length;

  String get severityLine => criticalCount == 0
      ? 'None of the rows read is marked as needing attention now.'
      : '$criticalCount ${criticalCount == 1 ? 'row is' : 'rows are'} marked as '
            'needing attention now.';
}
