import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// One `usage_daily` row, said the way a parent reads it.
final class UsageLine {
  const UsageLine(this.usage, {this.deviceName, this.isDemo = false});

  final UsageDaily usage;
  final String? deviceName;
  final bool isDemo;

  String get whose => deviceName ?? 'a device this build cannot name';

  String get appLabel =>
      usage.appLabel.isEmpty ? 'An app that reported no name' : usage.appLabel;

  String get day =>
      usage.day == null ? 'a day this row did not state' : _day(usage.day!);

  String get duration => _duration(usage.totalMs);

  String get lastUsed => usage.lastUsedAt == null
      ? 'the device did not report a last-used time'
      : 'last used ${usage.lastUsedAt!.toUtc().toIso8601String()}';

  static String _day(DateTime day) => '${day.day}/${day.month}/${day.year}';

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

/// A timeline activity event spanning usage, geofences, battery, or alerts.
final class TimelineActivityEvent {
  const TimelineActivityEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.category,
    this.deviceName,
    this.isDemo = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String category;
  final String? deviceName;
  final bool isDemo;
}

/// What the activity screen read, with timeline events and device mapping.
final class UsageBoard {
  const UsageBoard({
    required this.familyId,
    required this.lines,
    required this.deviceGap,
    this.deviceId,
    this.events = const [],
    this.isOffline = false,
  });

  final String familyId;
  final List<UsageLine> lines;
  final String? deviceId;
  final BlockedFailure? deviceGap;
  final List<TimelineActivityEvent> events;
  final bool isOffline;

  bool get hasLines => lines.isNotEmpty;
  bool get hasEvents => events.isNotEmpty;

  static const int window = 40;

  String get counted =>
      '${lines.length} ${lines.length == 1 ? 'day-row' : 'day-rows'} read for '
      '${deviceId == null ? 'this family' : 'one device'}.';
}
