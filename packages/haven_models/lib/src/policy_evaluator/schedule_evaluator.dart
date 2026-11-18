import '../policy_schedules.dart';
import 'schedule_evaluation_result.dart';

/// Pure-Dart deterministic evaluator for recurring schedules and intervals.
abstract final class ScheduleEvaluator {
  /// Evaluates whether a single [schedule] is active at [evaluationTime].
  ///
  /// Conforms to Decisions 2.19–2.25:
  /// - Half-open intervals: `[start, end)`. Start inclusive, end exclusive.
  /// - Equal start/end is zero-duration and inactive.
  /// - ISO weekdays 1..7 (Monday=1, Sunday=7). Empty days or any day outside
  ///   1..7 causes the schedule to be treated as fail-safe inactive.
  /// - Malformed time strings fail safe as inactive without runtime exceptions.
  /// - Device-local wall-clock time is authoritative via [DateTime.toLocal].
  /// - Minute precision: seconds and milliseconds are discarded.
  static bool isScheduleActive(
    PolicySchedule schedule,
    DateTime evaluationTime,
  ) {
    if (!schedule.isActive) return false;
    if (schedule.days.isEmpty) return false;
    if (schedule.days.any((d) => d < 1 || d > 7)) return false;

    final start = _parseMinutes(schedule.startTime);
    final end = _parseMinutes(schedule.endTime);
    if (start == null || end == null || start == end) return false;

    final localTime = evaluationTime.toLocal();
    final currentDay = localTime.weekday;
    final currentMinutes = localTime.hour * 60 + localTime.minute;

    if (start < end) {
      return schedule.days.contains(currentDay) &&
          currentMinutes >= start &&
          currentMinutes < end;
    } else {
      final isEveningMatch =
          schedule.days.contains(currentDay) && currentMinutes >= start;
      final previousDay = currentDay == 1 ? 7 : currentDay - 1;
      final isMorningMatch =
          schedule.days.contains(previousDay) && currentMinutes < end;
      return isEveningMatch || isMorningMatch;
    }
  }

  /// Evaluates all schedules in [schedules] at [evaluationTime] and computes
  /// restrictive whitelist intersection under Decision 2.6 and Decision 2.21.
  ///
  /// When no schedules are active (Decision 2.22), [ScheduleEvaluationResult] has
  /// [ScheduleEvaluationResult.isAnyScheduleActive] set to false, empty activeSchedules,
  /// and empty allowedAppExceptions.
  static ScheduleEvaluationResult evaluate({
    required List<PolicySchedule> schedules,
    required DateTime evaluationTime,
  }) {
    final active = <PolicySchedule>[];
    for (final schedule in schedules) {
      if (isScheduleActive(schedule, evaluationTime)) {
        active.add(schedule);
      }
    }

    if (active.isEmpty) {
      return ScheduleEvaluationResult(
        isAnyScheduleActive: false,
        isBedtimeActive: false,
        isSchoolActive: false,
        activeSchedules: const [],
        allowedAppExceptions: const {},
      );
    }

    final isBedtimeActive = active.any(
      (s) => s.type == PolicyScheduleType.bedtime,
    );
    final isSchoolActive = active.any(
      (s) => s.type == PolicyScheduleType.school,
    );

    // Restrictive intersection: start with first active schedule's whitelist.
    var allowedExceptions = active.first.allowedApps.toSet();
    for (var i = 1; i < active.length; i++) {
      allowedExceptions = allowedExceptions.intersection(
        active[i].allowedApps.toSet(),
      );
    }

    return ScheduleEvaluationResult(
      isAnyScheduleActive: true,
      isBedtimeActive: isBedtimeActive,
      isSchoolActive: isSchoolActive,
      activeSchedules: active,
      allowedAppExceptions: allowedExceptions,
    );
  }

  static int? _parseMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return h * 60 + m;
  }
}
