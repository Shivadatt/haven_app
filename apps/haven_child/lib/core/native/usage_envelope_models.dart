import 'usage_channel_contract.dart';

/// Standardized Usage Access permission status on Android.
enum UsagePermissionStatus {
  granted,
  denied,
  unsupported;

  static UsagePermissionStatus? parse(String? raw) => switch (raw) {
    UsagePermissionStatusValue.granted => UsagePermissionStatus.granted,
    UsagePermissionStatusValue.denied => UsagePermissionStatus.denied,
    UsagePermissionStatusValue.unsupported =>
      UsagePermissionStatus.unsupported,
    _ => null,
  };
}

/// Typed result of querying native Usage Access permission status.
final class UsagePermissionResult {
  const UsagePermissionResult({
    required this.status,
    required this.apiLevel,
  });

  final UsagePermissionStatus status;
  final int apiLevel;

  bool get isGranted => status == UsagePermissionStatus.granted;
}

/// Typed result of opening Android Usage Access settings.
final class UsageSettingsLaunchResult {
  const UsageSettingsLaunchResult({
    required this.intentLaunched,
    required this.openedPackageSettings,
    required this.apiLevel,
  });

  final bool intentLaunched;
  final bool openedPackageSettings;
  final int apiLevel;
}

/// Data freshness indicator reflecting Android UsageStatsManager batching.
enum UsageDataFreshness {
  recent,
  delayed,
  empty;

  static UsageDataFreshness? parse(String? raw) => switch (raw) {
    UsageDataFreshnessValue.recent => UsageDataFreshness.recent,
    UsageDataFreshnessValue.delayed => UsageDataFreshness.delayed,
    UsageDataFreshnessValue.empty => UsageDataFreshness.empty,
    _ => null,
  };
}

/// Per-application foreground usage record.
final class UsageAppRecord {
  const UsageAppRecord({
    required this.packageName,
    required this.totalForegroundMillis,
    required this.isSystemApp,
    this.lastTimeUsedMillis,
  });

  final String packageName;
  final int totalForegroundMillis;
  final int? lastTimeUsedMillis;
  final bool isSystemApp;

  Duration get foregroundDuration =>
      Duration(milliseconds: totalForegroundMillis);
}

/// Structured daily usage response envelope.
final class UsageDailyResult {
  const UsageDailyResult({
    required this.apiLevel,
    required this.startTimeMillis,
    required this.endTimeMillis,
    required this.totalForegroundMillis,
    required this.dataFreshness,
    required this.apps,
  });

  final int apiLevel;
  final int startTimeMillis;
  final int endTimeMillis;
  final int totalForegroundMillis;
  final UsageDataFreshness dataFreshness;
  final List<UsageAppRecord> apps;

  Duration get totalForegroundDuration =>
      Duration(milliseconds: totalForegroundMillis);
}
