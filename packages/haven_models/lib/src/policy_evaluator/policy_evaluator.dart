import 'policy_evaluation_context.dart';
import 'policy_evaluation_models.dart';
import 'policy_evaluator_helpers.dart';
import 'policy_usage_snapshot.dart';
import 'schedule_evaluator.dart';

/// Pure-Dart deterministic policy evaluation engine.
abstract final class PolicyEvaluator {
  /// Evaluates device and application policies under the 7-level precedence hierarchy.
  static PolicyEvaluationResult evaluate({
    required PolicyEvaluationContext context,
    required PolicyUsageSnapshot usage,
    Iterable<String>? targetPackages,
  }) {
    final scheduleResult = ScheduleEvaluator.evaluate(
      schedules: context.config.schedules,
      evaluationTime: context.evaluationTime,
    );

    // Decision 2.29: local date mismatch invalidates global and per-app usage.
    final isUsageValid = PolicyUsageSnapshot.isSameLocalDate(
          context.evaluationTime,
          usage.snapshotDate,
        ) &&
        usage.isPermissionGranted &&
        usage.freshness != PolicyUsageFreshness.unavailable;

    final dailyQuota = evaluateDailyQuota(context, usage, isUsageValid);

    // Decision 2.26: dynamic union when null; authoritative when provided.
    final targetSet = targetPackages?.toSet() ??
        {
          ...context.config.blockedApps,
          ...context.config.allowedApps,
          ...context.config.appLimits.keys,
          ...scheduleResult.activeSchedules.expand((s) => s.allowedApps),
          if (isUsageValid) ...usage.appForegroundMillis.keys,
        };

    final appEvaluations = {
      for (final pkg in targetSet)
        pkg: evaluateAppPolicy(
          pkg: pkg,
          context: context,
          usage: usage,
          isUsageValid: isUsageValid,
          scheduleResult: scheduleResult,
          dailyQuota: dailyQuota,
        ),
    };

    final (overallState, primaryReason, secondaryReasons) =
        deriveOverallState(scheduleResult, dailyQuota, usage, isUsageValid);

    return PolicyEvaluationResult(
      overallState: overallState,
      evaluationTime: context.evaluationTime,
      activeSchedules: scheduleResult.activeSchedules,
      dailyQuota: dailyQuota,
      appEvaluations: appEvaluations,
      isDowntimeActive: scheduleResult.isBedtimeActive,
      primaryReason: primaryReason,
      secondaryReasons: secondaryReasons,
      usageCompleteness:
          isUsageValid ? usage.completeness : PolicyUsageCompleteness.unknown,
      isDelayed: usage.freshness == PolicyUsageFreshness.delayed,
    );
  }
}
