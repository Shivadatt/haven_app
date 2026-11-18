import 'package:meta/meta.dart';
import '../policy_schedules.dart';

/// Pure-Dart evaluation result for active policy schedules at an evaluation instant.
@immutable
final class ScheduleEvaluationResult {
  ScheduleEvaluationResult({
    required this.isAnyScheduleActive,
    required this.isBedtimeActive,
    required this.isSchoolActive,
    required List<PolicySchedule> activeSchedules,
    required Set<String> allowedAppExceptions,
  })  : activeSchedules = List.unmodifiable(activeSchedules),
        allowedAppExceptions = Set.unmodifiable(allowedAppExceptions);

  /// True if at least one schedule is currently active.
  final bool isAnyScheduleActive;

  /// True if an active schedule is of type [PolicyScheduleType.bedtime].
  final bool isBedtimeActive;

  /// True if an active schedule is of type [PolicyScheduleType.school].
  final bool isSchoolActive;

  /// Unmodifiable list of all schedules active at evaluation time.
  final List<PolicySchedule> activeSchedules;

  /// Set of package names permitted across ALL active schedules via
  /// restrictive intersection (Decision 2.6).
  ///
  /// CRITICAL (Decision 2.22): When no schedules are active, this set is empty.
  /// An empty exception set must NOT independently be interpreted as lockdown.
  /// Callers must check [isAnyScheduleActive] before applying restrictions.
  final Set<String> allowedAppExceptions;

  /// Helper checking if [packageName] is in [allowedAppExceptions].
  ///
  /// Callers MUST verify [isAnyScheduleActive] before treating false as a restriction.
  bool isAppAllowed(String packageName) =>
      allowedAppExceptions.contains(packageName);
}
