import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// One `usage_daily` row, said the way a parent reads it.
///
/// The row is already the minimised form the backend keeps: one package, one
/// day, one total. Nothing here adds a category, a screen-time score or a
/// comparison, because no captured column supports one — see
/// `docs/stage1/03-data-model.md:56`, which describes this table as
/// "already a minimised form".
final class UsageLine {
  const UsageLine(this.usage, {this.deviceName});

  final UsageDaily usage;

  /// The device row this usage came from, when one could be read. `usage_daily`
  /// carries only a device id, so the name has to come from the device table.
  final String? deviceName;

  String get whose => deviceName ?? 'a device this build cannot name';

  String get appLabel =>
      usage.appLabel.isEmpty ? 'An app that reported no name' : usage.appLabel;

  /// The day the row is for, or the truth when the row arrived without one
  /// (`UsageDaily.day` is nullable on purpose).
  String get day =>
      usage.day == null ? 'a day this row did not state' : _day(usage.day!);

  String get duration => _duration(usage.totalMs);

  /// `last_used_at` is the only moment in the row that is not a whole day.
  String get lastUsed => usage.lastUsedAt == null
      ? 'the device did not report a last-used time'
      : 'last used ${usage.lastUsedAt!.toUtc().toIso8601String()}';

  static String _day(DateTime day) => '${day.day}/${day.month}/${day.year}';

  /// Hours and minutes, because a parent comparing two apps thinks in those
  /// units. This is the row's own `total_ms`, not a rounded estimate.
  static String _duration(int totalMs) {
    if (totalMs <= 0) return 'no time reported';
    final int minutes = (totalMs / 60000).floor();
    if (minutes < 1) return 'under a minute';
    final int hours = minutes ~/ 60;
    final int rest = minutes % 60;
    if (hours == 0) return '$rest m';
    return '$hours h ${rest.toString().padLeft(2, '0')} m';
  }
}

/// What the activity screen actually read, plus the one thing it could not
/// resolve about those rows.
final class UsageBoard {
  const UsageBoard({
    required this.familyId,
    required this.lines,
    required this.deviceGap,
    this.deviceId,
  });

  final String familyId;
  final List<UsageLine> lines;

  /// The device the read was narrowed to, or null when the whole family was
  /// read. The route argument decides this (`00-app-contract.md:162`); the
  /// family id always goes with it, so a wrong device id reads nothing rather
  /// than reading someone else's.
  final String? deviceId;

  /// The refusal that says whose phone each row came from, or null when the
  /// device rows were readable. It is part of the board because `usage_daily`
  /// carries only a device id and this build cannot read `devices` (F6).
  final BlockedFailure? deviceGap;

  bool get hasLines => lines.isNotEmpty;

  /// How many rows the screen asked for. The window is a page size, so the
  /// screen says "read" and never implies it saw the whole history.
  static const int window = 40;

  String get counted =>
      '${lines.length} ${lines.length == 1 ? 'day-row' : 'day-rows'} read for '
      '${deviceId == null ? 'this family' : 'one device'}.';
}
