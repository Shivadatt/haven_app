import 'package:meta/meta.dart';

import '../policy_schedules.dart';
import 'policy_usage_snapshot.dart';

/// High-level device policy evaluation state.
enum PolicyOverallState {
  allowed,
  bedtimeActive,
  schoolActive,
  scheduleRestricted,
  dailyLimitReached,
  dailyLimitExceeded,
  usageUnavailable,
}

/// Granular status for a specific application package.
enum AppPolicyStatus {
  exempt,
  allowed,
  scheduleAllowed,
  scheduleRestricted,
  appLimitReached,
  dailyLimitReached,
  blockedByParent,
  usageUnavailable,
}

/// Evaluation metrics for the device-wide daily screen time quota.
@immutable
final class DailyQuotaEvaluation {
  const DailyQuotaEvaluation({
    required this.limitMinutes,
    required this.usedMinutes,
    required this.remainingMinutes,
    required this.isReached,
    required this.isExceeded,
    required this.isUnavailable,
    required this.isUnlimited,
  });

  final int? limitMinutes;
  final int? usedMinutes;
  final int? remainingMinutes;
  final bool isReached;
  final bool isExceeded;
  final bool isUnavailable;
  final bool isUnlimited;
}

/// Evaluation record for an individual application package.
@immutable
final class AppEvaluation {
  const AppEvaluation({
    required this.packageName,
    required this.status,
    required this.reason,
    required this.usedMinutes,
    this.limitMinutes,
    this.remainingMinutes,
  });

  final String packageName;
  final AppPolicyStatus status;
  final String reason;
  final int? usedMinutes;
  final int? limitMinutes;
  final int? remainingMinutes;

  /// Returns true if the status represents an active restriction.
  bool get isRestricted =>
      status == AppPolicyStatus.scheduleRestricted ||
      status == AppPolicyStatus.appLimitReached ||
      status == AppPolicyStatus.dailyLimitReached ||
      status == AppPolicyStatus.blockedByParent;
}

/// Comprehensive, immutable result of a deterministic policy evaluation run.
@immutable
final class PolicyEvaluationResult {
  PolicyEvaluationResult({
    required this.overallState,
    required this.evaluationTime,
    required List<PolicySchedule> activeSchedules,
    required this.dailyQuota,
    required Map<String, AppEvaluation> appEvaluations,
    required this.isDowntimeActive,
    required this.primaryReason,
    List<String> secondaryReasons = const [],
    this.usageCompleteness = PolicyUsageCompleteness.complete,
    this.isDelayed = false,
  }) : activeSchedules = List.unmodifiable(activeSchedules),
       appEvaluations = Map.unmodifiable(appEvaluations),
       secondaryReasons = List.unmodifiable(secondaryReasons);

  final PolicyOverallState overallState;
  final DateTime evaluationTime;
  final List<PolicySchedule> activeSchedules;
  final DailyQuotaEvaluation dailyQuota;
  final Map<String, AppEvaluation> appEvaluations;
  final bool isDowntimeActive;
  final String primaryReason;
  final List<String> secondaryReasons;
  final PolicyUsageCompleteness usageCompleteness;
  final bool isDelayed;

  /// Mandatory non-enforcement disclosure required by Decision 4.4.
  String get disclosure =>
      'Policies are evaluated locally. Application blocking is not enforced on this build.';
}
