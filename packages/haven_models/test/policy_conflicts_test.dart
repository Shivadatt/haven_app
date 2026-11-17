import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

void main() {
  group('ScheduleConflict', () {
    test('summary describes the overlap accurately', () {
      final s1 = PolicySchedule.defaultBedtime();
      final s2 = PolicySchedule.defaultSchool();
      final conflict = ScheduleConflict(
        scheduleA: s1,
        scheduleB: s2,
        overlappingDays: const [1, 2],
      );
      expect(conflict.summary, '"Bedtime" overlaps with "School Hours" on Mon, Tue.');
    });
  });

  group('ScheduleConflictDetector', () {
    test('findConflicts detects daytime overlap on common days', () {
      const s1 = PolicySchedule(
        id: '1',
        name: 'Morning Study',
        type: PolicyScheduleType.custom,
        startTime: '09:00',
        endTime: '11:00',
        days: [1, 2, 3],
      );
      const s2 = PolicySchedule(
        id: '2',
        name: 'Late Morning',
        type: PolicyScheduleType.custom,
        startTime: '10:30',
        endTime: '12:00',
        days: [2, 3, 4],
      );

      final conflicts = ScheduleConflictDetector.findConflicts(
        candidate: s1,
        existingList: [s2],
      );

      expect(conflicts.length, 1);
      expect(conflicts.first.overlappingDays, [2, 3]);
    });

    test('findConflicts ignores schedules on different days', () {
      const s1 = PolicySchedule(
        id: '1',
        name: 'Mon Study',
        type: PolicyScheduleType.custom,
        startTime: '09:00',
        endTime: '11:00',
        days: [1],
      );
      const s2 = PolicySchedule(
        id: '2',
        name: 'Tue Study',
        type: PolicyScheduleType.custom,
        startTime: '09:00',
        endTime: '11:00',
        days: [2],
      );

      final conflicts = ScheduleConflictDetector.findConflicts(
        candidate: s1,
        existingList: [s2],
      );

      expect(conflicts, isEmpty);
    });

    test('findConflicts ignores inactive schedules', () {
      const s1 = PolicySchedule(
        id: '1',
        name: 'Study',
        type: PolicyScheduleType.custom,
        startTime: '09:00',
        endTime: '11:00',
        days: [1],
        isActive: false,
      );
      const s2 = PolicySchedule(
        id: '2',
        name: 'Other',
        type: PolicyScheduleType.custom,
        startTime: '09:00',
        endTime: '11:00',
        days: [1],
      );

      expect(
        ScheduleConflictDetector.findConflicts(
          candidate: s1,
          existingList: [s2],
        ),
        isEmpty,
      );
    });

    test('findConflicts detects overnight schedule overlap', () {
      final bedtime = PolicySchedule.defaultBedtime(); // 21:00 to 07:00
      const earlyMorning = PolicySchedule(
        id: 'early',
        name: 'Early Morning',
        type: PolicyScheduleType.custom,
        startTime: '06:00',
        endTime: '08:00',
        days: [1, 2, 3, 4, 5, 6, 7],
      );

      final conflicts = ScheduleConflictDetector.findConflicts(
        candidate: bedtime,
        existingList: [earlyMorning],
      );

      expect(conflicts.length, 1);
      expect(conflicts.first.scheduleB.id, 'early');
    });

    test('hasDuplicateName detects duplicates ignoring case and whitespace', () {
      final list = [
        PolicySchedule.defaultBedtime(),
        PolicySchedule.defaultSchool(),
      ];

      expect(
        ScheduleConflictDetector.hasDuplicateName(
          name: '  bedtime  ',
          existingList: list,
        ),
        isTrue,
      );
      expect(
        ScheduleConflictDetector.hasDuplicateName(
          name: 'School Hours',
          existingList: list,
          excludeId: 'sched-school',
        ),
        isFalse,
      );
      expect(
        ScheduleConflictDetector.hasDuplicateName(
          name: '',
          existingList: list,
        ),
        isFalse,
      );
    });
  });
}
