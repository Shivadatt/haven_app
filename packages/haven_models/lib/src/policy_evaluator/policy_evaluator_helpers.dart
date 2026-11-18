import 'dart:math' as math;

import 'policy_evaluation_context.dart';
import 'policy_evaluation_models.dart';
import 'policy_usage_snapshot.dart';
import 'schedule_evaluation_result.dart';

/// Evaluates daily screen time quota under Decisions 2.3, 2.7, 2.9, 2.13, 2.29, 2.30.
DailyQuotaEvaluation evaluateDailyQuota(
  PolicyEvaluationContext context,
  PolicyUsageSnapshot usage,
  bool isUsageValid,
) {
  final limit = context.effectiveDailyLimit;
  final used = isUsageValid ? usage.totalMinutes : null;
  final isUnlimited = limit == null;
  final isUnavailable = limit != null && used == null;
  final isReached =
      limit != null && (limit == 0 || (used != null && used >= limit));
  final isExceeded = limit != null && used != null && used > limit;
  final remaining =
      (limit != null && used != null) ? math.max(0, limit - used) : null;

  return DailyQuotaEvaluation(
    limitMinutes: limit,
    usedMinutes: used,
    remainingMinutes: remaining,
    isReached: isReached,
    isExceeded: isExceeded,
    isUnavailable: isUnavailable,
    isUnlimited: isUnlimited,
  );
}

/// Evaluates an individual package under the 7-level priority hierarchy.
AppEvaluation evaluateAppPolicy({
  required String pkg,
  required PolicyEvaluationContext context,
  required PolicyUsageSnapshot usage,
  required bool isUsageValid,
  required ScheduleEvaluationResult scheduleResult,
  required DailyQuotaEvaluation dailyQuota,
}) {
  final appMinutes = isUsageValid ? usage.appMinutes(pkg) : null;
  final limitMinutes = context.config.appLimits[pkg];
  final remainingMinutes = (limitMinutes != null && appMinutes != null)
      ? math.max(0, limitMinutes - appMinutes)
      : null;

  final AppPolicyStatus status;
  final String reason;

  // Level 1: Parent Blocklist (Absolute Hard Veto)
  if (context.config.blockedApps.contains(pkg)) {
    status = AppPolicyStatus.blockedByParent;
    reason = 'Blocked by parent';
  }
  // Level 2: Emergency Defaults (Decisions 2.2, 2.10, 2.28)
  else if (PolicyEvaluationContext.isEmergencyPackage(pkg)) {
    status = AppPolicyStatus.exempt;
    reason = 'Emergency service';
  }
  // Level 3: Active Restrictive Schedules (Decisions 2.6, 2.11)
  else if (scheduleResult.isAnyScheduleActive &&
      !scheduleResult.allowedAppExceptions.contains(pkg)) {
    status = AppPolicyStatus.scheduleRestricted;
    reason = scheduleResult.isBedtimeActive
        ? 'Bedtime active'
        : 'Schedule restricted';
  }
  // Level 4: Explicit Per-App Time Limits (Decision 2.5)
  else if (limitMinutes != null &&
      appMinutes != null &&
      appMinutes >= limitMinutes) {
    status = AppPolicyStatus.appLimitReached;
    reason = 'App limit reached';
  }
  // Level 5: Global Daily Screen Time Quota (Decision 2.1)
  else if (dailyQuota.isReached &&
      !context.config.allowedApps.contains(pkg)) {
    status = AppPolicyStatus.dailyLimitReached;
    reason = 'Daily limit reached';
  }
  // Level 6 & 7: Parent Whitelist Exemption or Default Permitted
  else {
    final isSched = scheduleResult.isAnyScheduleActive;
    final isWhite = context.config.allowedApps.contains(pkg);
    status =
        isSched ? AppPolicyStatus.scheduleAllowed : AppPolicyStatus.allowed;
    reason = isSched
        ? 'Allowed during schedule'
        : (isWhite ? 'Parent whitelist exempt' : 'Allowed');
  }

  return AppEvaluation(
    packageName: pkg,
    status: status,
    reason: reason,
    usedMinutes: appMinutes,
    limitMinutes: limitMinutes,
    remainingMinutes: remainingMinutes,
  );
}

/// Derives overall device-level state under Decisions 2.27 and 2.30.
(PolicyOverallState, String, List<String>) deriveOverallState(
  ScheduleEvaluationResult scheduleResult,
  DailyQuotaEvaluation dailyQuota,
  PolicyUsageSnapshot usage,
  bool isUsageValid,
) {
  final secondary = <String>[
    if (usage.freshness == PolicyUsageFreshness.delayed)
      'Usage data is delayed',
    if (!isUsageValid) 'Usage data unavailable',
    if (scheduleResult.isAnyScheduleActive && dailyQuota.isReached)
      dailyQuota.isExceeded
          ? 'Daily screen time limit exceeded'
          : 'Daily screen time limit reached',
  ];

  final PolicyOverallState state;
  final String primary;

  // Decision 2.27: Schedule visual priority over global daily quota
  if (scheduleResult.isBedtimeActive) {
    state = PolicyOverallState.bedtimeActive;
    primary = 'Bedtime active';
  } else if (scheduleResult.isSchoolActive) {
    state = PolicyOverallState.schoolActive;
    primary = 'School schedule active';
  } else if (scheduleResult.isAnyScheduleActive) {
    state = PolicyOverallState.scheduleRestricted;
    primary = 'Schedule active';
  } else if (dailyQuota.isExceeded) {
    state = PolicyOverallState.dailyLimitExceeded;
    primary = 'Daily screen time limit exceeded';
  } else if (dailyQuota.isReached) {
    state = PolicyOverallState.dailyLimitReached;
    primary = 'Daily screen time limit reached';
  } else {
    state = PolicyOverallState.allowed;
    primary = 'All clear';
  }

  return (state, primary, secondary);
}
