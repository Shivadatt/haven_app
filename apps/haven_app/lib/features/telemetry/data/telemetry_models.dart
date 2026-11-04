import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// One `audit_logs` row: something the backend recorded, in its own words.
///
/// `event_type` is free text between 1 and 80 characters with no CHECK list
/// behind it, so it is echoed rather than mapped onto an invented category, and
/// `metadata` is a JSON object nobody has specified — its contents stay unread.
final class AuditLine {
  const AuditLine(this.entry, {this.deviceName});

  final AuditLog entry;

  /// The device the row names, when a device row could be read for that id.
  final String? deviceName;

  String get what => entry.eventType.isEmpty
      ? 'A change with no kind recorded'
      : 'Recorded as: ${entry.eventType}';

  String get when => 'at ${entry.createdAt.toUtc().toIso8601String()}';

  /// `target_type` is free text (up to 40) and `target_id` up to 128. Neither is
  /// a name, so the row says what kind of thing changed without pretending to
  /// identify it.
  String get about {
    final String? kind = entry.targetType;
    if (kind == null || kind.isEmpty) return 'about the family as a whole';
    return 'about something recorded as a $kind';
  }

  /// A device id in an audit row is a fact about the row, not a name the parent
  /// can act on — and the table that would name it is unreachable (F6).
  String? get whose => deviceName;

  /// The metadata object is deliberately not printed: it is unspecified, and an
  /// audit note is exactly where a value nobody agreed to store could be hiding.
  String get notes => entry.metadata.isEmpty
      ? 'nothing else was stored with it'
      : '${entry.metadata.length} note(s) stored with it, not shown here';
}

/// What the family's trail can show, and the two things it cannot.
final class TelemetryBoard {
  const TelemetryBoard({
    required this.familyId,
    required this.lines,
    required this.offlineGap,
    this.deviceGap,
    this.deviceId,
  });

  final String familyId;

  /// The device the read was narrowed to, or null for the whole family.
  final String? deviceId;
  final List<AuditLine> lines;

  /// Whether a device is online is a `devices.last_seen_at` read plus a sweep.
  /// The column is unreachable and the sweep is an RPC this role cannot call.
  final BlockedFailure offlineGap;

  /// The refusal that would otherwise name each row's device.
  final BlockedFailure? deviceGap;

  bool get hasLines => lines.isNotEmpty;

  /// A page size, not a history: no captured rule says how long `audit_logs`
  /// rows are kept, so this screen never claims to show everything that happened.
  static const int window = 20;

  String get counted =>
      '${lines.length} ${lines.length == 1 ? "entry" : "entries"} read — the '
      'newest $window rows the backend would give, for '
      '${deviceId == null ? 'this family' : 'one device'}.';
}
