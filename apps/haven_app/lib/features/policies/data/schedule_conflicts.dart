import 'policy_schedules.dart';

/// Represents a detected timing overlap between two active schedules.
final class ScheduleConflict {
  const ScheduleConflict({
    required this.scheduleA,
    required this.scheduleB,
    required this.overlappingDays,
  });

  final PolicySchedule scheduleA;
  final PolicySchedule scheduleB;
  final List<int> overlappingDays;

  String get summary {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayNames = overlappingDays.map((d) => names[d]).join(', ');
    return '"${scheduleA.name}" overlaps with "${scheduleB.name}" on $dayNames.';
  }
}

/// Detects time window conflicts and duplicate schedules.
abstract final class ScheduleConflictDetector {
  /// Checks if [candidate] conflicts with any active schedule in [existingList].
  static List<ScheduleConflict> findConflicts({
    required PolicySchedule candidate,
    required List<PolicySchedule> existingList,
  }) {
    if (!candidate.isActive) return const [];
    final List<ScheduleConflict> conflicts = [];

    for (final other in existingList) {
      if (other.id == candidate.id || !other.isActive) continue;

      final commonDays = candidate.days.where((d) => other.days.contains(d)).toList();
      if (commonDays.isEmpty) continue;

      if (_timesOverlap(candidate, other)) {
        conflicts.add(ScheduleConflict(
          scheduleA: candidate,
          scheduleB: other,
          overlappingDays: commonDays,
        ));
      }
    }
    return conflicts;
  }

  /// Checks whether [name] duplicates any existing schedule (ignoring [excludeId]).
  static bool hasDuplicateName({
    required String name,
    required List<PolicySchedule> existingList,
    String? excludeId,
  }) {
    final clean = name.trim().toLowerCase();
    if (clean.isEmpty) return false;
    for (final s in existingList) {
      if (excludeId != null && s.id == excludeId) continue;
      if (s.name.trim().toLowerCase() == clean) return true;
    }
    return false;
  }

  static bool _timesOverlap(PolicySchedule a, PolicySchedule b) {
    final startA = _toMinutes(a.startTime);
    final endA = _toMinutes(a.endTime);
    final startB = _toMinutes(b.startTime);
    final endB = _toMinutes(b.endTime);
    if (startA == null || endA == null || startB == null || endB == null) return false;

    final intervalsA = _toDailyIntervals(startA, endA);
    final intervalsB = _toDailyIntervals(startB, endB);

    for (final (sA, eA) in intervalsA) {
      for (final (sB, eB) in intervalsB) {
        if (sA < eB && sB < eA) return true;
      }
    }
    return false;
  }

  static List<(int, int)> _toDailyIntervals(int start, int end) {
    if (start < end) {
      return [(start, end)];
    } else {
      // Overnight: e.g. 21:00 to 07:00 => [21:00..1440] and [0..07:00]
      return [
        (start, 1440),
        (0, end),
      ];
    }
  }

  static int? _toMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }
}
