import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../core/native/usage_envelope_models.dart';

/// Pure conversion and validation for policy usage snapshots.
///
/// The Stage 3 native envelope has no completeness evidence. A native total is
/// therefore never used as a full-day quota input; measured positive per-app
/// records may still be retained for explicit per-app evaluation.
abstract final class PolicyUsageAdapter {
  /// Returns the intended local-day acquisition window.
  ///
  /// At exact local midnight this intentionally returns an equal interval.
  /// Callers must not send an equal interval to the usage channel.
  static ({int start, int end}) dailyRange(DateTime evaluationTime) {
    final local = evaluationTime.toLocal();
    final start = DateTime(local.year, local.month, local.day);
    return (
      start: start.millisecondsSinceEpoch,
      end: evaluationTime.millisecondsSinceEpoch,
    );
  }

  /// Converts a successful native result into a policy snapshot.
  static Result<PolicyUsageSnapshot> fromDailyResult(
    UsageDailyResult result, {
    required bool isPermissionGranted,
  }) {
    final start = DateTime.fromMillisecondsSinceEpoch(result.startTimeMillis);
    final end = DateTime.fromMillisecondsSinceEpoch(result.endTimeMillis);
    if (!end.isAfter(start)) return _malformed();

    final apps = <String, int>{};
    var hasPositive = false;
    for (final app in result.apps) {
      if (app.packageName.trim().isEmpty ||
          app.totalForegroundMillis < 0 ||
          apps.containsKey(app.packageName)) {
        return _malformed();
      }
      apps[app.packageName] = app.totalForegroundMillis;
      if (app.totalForegroundMillis > 0) hasPositive = true;
    }

    final snapshotDate = DateTime(start.year, start.month, start.day);
    if (result.dataFreshness == UsageDataFreshness.empty || !hasPositive) {
      return Ok(
        PolicyUsageSnapshot.unavailable(
          snapshotDate: snapshotDate,
          snapshotTime: end,
          startInterval: start,
          endInterval: end,
          isPermissionGranted: isPermissionGranted,
        ),
      );
    }

    return Ok(
      PolicyUsageSnapshot(
        snapshotDate: snapshotDate,
        snapshotTime: end,
        startInterval: start,
        endInterval: end,
        totalForegroundMillis: null,
        appForegroundMillis: apps,
        completeness: PolicyUsageCompleteness.unknown,
        freshness: result.dataFreshness == UsageDataFreshness.delayed
            ? PolicyUsageFreshness.delayed
            : PolicyUsageFreshness.recent,
        isPermissionGranted: isPermissionGranted,
      ),
    );
  }

  /// Builds an explicit unavailable snapshot for the intended query window.
  ///
  /// The interval is the attempted evaluation window, not observed usage.
  /// Equal boundaries are valid here for the exact-local-midnight exception.
  static PolicyUsageSnapshot unavailableForQuery({
    required int startTimeMillis,
    required int endTimeMillis,
    required bool isPermissionGranted,
  }) {
    final start = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
    final end = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
    return PolicyUsageSnapshot.unavailable(
      snapshotDate: DateTime(start.year, start.month, start.day),
      snapshotTime: end,
      startInterval: start,
      endInterval: end,
      isPermissionGranted: isPermissionGranted,
    );
  }

  static Err<PolicyUsageSnapshot> _malformed() => const Err(
    BackendFailure(
      'Malformed native usage interval or app record',
      code: 'malformed_response',
    ),
  );
}
