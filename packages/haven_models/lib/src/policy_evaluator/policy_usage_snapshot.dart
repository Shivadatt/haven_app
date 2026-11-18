import 'package:meta/meta.dart';

/// Completeness status of the supplied usage telemetry dataset.
enum PolicyUsageCompleteness {
  /// Confirmed complete snapshot across all active applications.
  complete,
  /// Partial or truncated snapshot (e.g. capped top N apps or partial query).
  incomplete,
  /// Completeness cannot be verified or evidence is absent.
  unknown,
}

/// Telemetry pipeline recency status reflecting native OS query freshness.
enum PolicyUsageFreshness {
  /// Telemetry reflects recent usage data up to native threshold (e.g. 15m).
  recent,
  /// Telemetry is delayed by native OS batching or throttling (>15m lag).
  delayed,
  /// Telemetry freshness is unknown (e.g. native empty activity without timestamp).
  unknown,
  /// Telemetry was not returned or could not be queried.
  unavailable;

  /// Safe conversion from Stage 3 native envelope freshness tokens.
  static PolicyUsageFreshness fromNativeFreshness(String? raw) => switch (raw) {
    'recent' => PolicyUsageFreshness.recent,
    'delayed' => PolicyUsageFreshness.delayed,
    'empty' => PolicyUsageFreshness.unknown,
    _ => PolicyUsageFreshness.unavailable,
  };
}

/// Immutable, pure-Dart transient snapshot of application foreground usage.
@immutable
final class PolicyUsageSnapshot {
  /// Primary generative constructor enforcing production-safe runtime validation.
  PolicyUsageSnapshot({
    required this.snapshotDate,
    required this.snapshotTime,
    required this.startInterval,
    required this.endInterval,
    required this.totalForegroundMillis,
    required Map<String, int> appForegroundMillis,
    required this.completeness,
    required this.freshness,
    required this.isPermissionGranted,
  }) : appForegroundMillis =
           Map.unmodifiable(Map<String, int>.from(appForegroundMillis)) {
    if (totalForegroundMillis != null && totalForegroundMillis! < 0) {
      throw ArgumentError.value(
        totalForegroundMillis,
        'totalForegroundMillis',
        'Total daily foreground millis cannot be negative.',
      );
    }
    for (final entry in this.appForegroundMillis.entries) {
      if (entry.key.trim().isEmpty) {
        throw ArgumentError.value(
          entry.key,
          'appForegroundMillis',
          'Package identifier key cannot be empty or whitespace.',
        );
      }
      if (entry.value < 0) {
        throw ArgumentError.value(
          entry.value,
          'appForegroundMillis[${entry.key}]',
          'Per-package foreground millis cannot be negative.',
        );
      }
    }
    if (endInterval.isBefore(startInterval)) {
      throw ArgumentError.value(
        endInterval,
        'endInterval',
        'End interval cannot precede start interval.',
      );
    }
  }

  /// Factory creating an explicit unavailable snapshot.
  factory PolicyUsageSnapshot.unavailable({
    required DateTime snapshotDate,
    required DateTime snapshotTime,
    required DateTime startInterval,
    required DateTime endInterval,
    bool isPermissionGranted = false,
  }) => PolicyUsageSnapshot(
    snapshotDate: snapshotDate,
    snapshotTime: snapshotTime,
    startInterval: startInterval,
    endInterval: endInterval,
    totalForegroundMillis: null,
    appForegroundMillis: const <String, int>{},
    completeness: PolicyUsageCompleteness.unknown,
    freshness: PolicyUsageFreshness.unavailable,
    isPermissionGranted: isPermissionGranted,
  );

  /// Factory creating an empty snapshot with zero total and per-package foreground usage.
  factory PolicyUsageSnapshot.empty({
    required DateTime snapshotDate,
    required DateTime snapshotTime,
    required DateTime startInterval,
    required DateTime endInterval,
    required bool isPermissionGranted,
    PolicyUsageCompleteness completeness = PolicyUsageCompleteness.unknown,
    PolicyUsageFreshness freshness = PolicyUsageFreshness.unknown,
  }) => PolicyUsageSnapshot(
    snapshotDate: snapshotDate,
    snapshotTime: snapshotTime,
    startInterval: startInterval,
    endInterval: endInterval,
    totalForegroundMillis: 0,
    appForegroundMillis: const <String, int>{},
    completeness: completeness,
    freshness: freshness,
    isPermissionGranted: isPermissionGranted,
  );

  /// Device-local calendar date of the observation interval.
  final DateTime snapshotDate;
  /// Wall-clock instant when this snapshot was queried/assembled.
  final DateTime snapshotTime;
  /// Local wall-clock start of the observation interval (local midnight).
  final DateTime startInterval;
  /// Local wall-clock end of the observation interval.
  final DateTime endInterval;
  /// Aggregate foreground screen time in milliseconds across the device.
  final int? totalForegroundMillis;
  /// Immutable map of package identifier to foreground milliseconds.
  final Map<String, int> appForegroundMillis;
  /// Completeness indicator (Decision 2.16).
  final PolicyUsageCompleteness completeness;
  /// Native telemetry freshness indicator (Decision 2.17).
  final PolicyUsageFreshness freshness;
  /// Whether USAGE_STATS permission was granted at capture time.
  final bool isPermissionGranted;

  /// Total measured foreground screen time in whole minutes.
  int? get totalMinutes =>
      totalForegroundMillis != null ? totalForegroundMillis! ~/ 60000 : null;

  /// Total measured foreground duration, or null if unmeasured.
  Duration? get totalForegroundDuration => totalForegroundMillis != null
      ? Duration(milliseconds: totalForegroundMillis!)
      : null;

  /// Whether the snapshot records zero foreground activity today.
  bool get isEmptyActivity =>
      totalForegroundMillis == 0 &&
      (appForegroundMillis.isEmpty ||
          appForegroundMillis.values.every((m) => m == 0));

  /// Whether the snapshot has any recorded foreground activity today.
  bool get hasRecordedActivity =>
      (totalForegroundMillis != null && totalForegroundMillis! > 0) ||
      appForegroundMillis.values.any((m) => m > 0);

  /// Resolves foreground minutes for [packageName] under Decision 2.16.
  int? appMinutes(String packageName) {
    if (appForegroundMillis.containsKey(packageName)) {
      return (appForegroundMillis[packageName] ?? 0) ~/ 60000;
    }
    if (completeness == PolicyUsageCompleteness.complete &&
        isPermissionGranted &&
        freshness != PolicyUsageFreshness.unavailable) {
      return 0;
    }
    return null;
  }

  /// Resolves foreground [Duration] for [packageName], or null if unmeasured.
  Duration? appDuration(String packageName) {
    final minutes = appMinutes(packageName);
    return minutes != null ? Duration(minutes: minutes) : null;
  }

  /// Decision 2.18: Device-local calendar date comparison helper.
  static bool isSameLocalDate(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }
}
