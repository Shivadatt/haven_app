import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/policies/controllers/schedules_editor_controller.dart';
import 'package:haven_app/features/policies/data/policy_schedules.dart';
import 'package:haven_app/features/policies/data/schedule_conflicts.dart';

import 'fakes.dart';

void main() {
  late FakePoliciesRepository repo;
  late SchedulesEditorController controller;

  setUp(() {
    repo = FakePoliciesRepository();
    controller = SchedulesEditorController(repository: repo);
  });

  tearDown(() {
    controller.dispose();
  });

  group('Advanced Schedules Editor - MODULE G', () {
    test('loads default schedules and categorizes correctly', () async {
      await controller.load();
      expect(controller.schedules.length, 2);
      expect(controller.bedtimeSchedules.length, 1);
      expect(controller.schoolSchedules.length, 1);
      expect(controller.customSchedules.isEmpty, isTrue);
    });

    test('bedtime schedule supports overnight timing and format', () async {
      await controller.load();
      final bedtime = controller.bedtimeSchedules.first;
      expect(bedtime.isOvernight, isTrue);
      expect(bedtime.formattedTimes, contains('Next day'));

      final edited = bedtime.copyWith(startTime: '22:00', endTime: '06:30');
      final ok = await controller.saveSchedule(edited);
      expect(ok, isTrue);
      expect(controller.bedtimeSchedules.first.startTime, '22:00');
      expect(controller.bedtimeSchedules.first.endTime, '06:30');
    });

    test('school schedule supports allowed app exceptions', () async {
      await controller.load();
      final school = controller.schoolSchedules.first;
      final withApps = school.copyWith(
        allowedApps: ['com.android.calculator2', 'com.google.android.apps.docs', 'com.duolingo'],
      );

      final ok = await controller.saveSchedule(withApps);
      expect(ok, isTrue);
      final updated = controller.schoolSchedules.first;
      expect(updated.allowedApps.length, 3);
      expect(updated.allowedApps, contains('com.duolingo'));
    });

    test('custom schedule creation, duplicate prevention, and deletion', () async {
      await controller.load();
      final custom = controller.createDraft(PolicyScheduleType.custom).copyWith(
        name: 'Homework Focus',
        category: 'Homework',
        startTime: '16:00',
        endTime: '17:30',
        days: [1, 2, 3, 4],
      );

      final ok = await controller.saveSchedule(custom);
      expect(ok, isTrue);
      expect(controller.customSchedules.length, 1);
      expect(controller.customSchedules.first.name, 'Homework Focus');
      expect(controller.customSchedules.first.category, 'Homework');

      // Duplicate name prevention
      final duplicate = controller.createDraft(PolicyScheduleType.custom).copyWith(
        name: 'Homework Focus',
      );
      final dupResult = await controller.saveSchedule(duplicate);
      expect(dupResult, isFalse);
      expect(controller.errorMessage.value, contains('already exists'));

      // Delete
      final delResult = await controller.deleteSchedule(custom.id);
      expect(delResult, isTrue);
      expect(controller.customSchedules.isEmpty, isTrue);
    });

    test('conflict detection catches overlapping active schedules on same days', () {
      final sched1 = const PolicySchedule(
        id: '1',
        name: 'Focus 1',
        type: PolicyScheduleType.custom,
        startTime: '14:00',
        endTime: '16:00',
        days: [1, 2, 3],
      );
      final sched2 = const PolicySchedule(
        id: '2',
        name: 'Focus 2',
        type: PolicyScheduleType.custom,
        startTime: '15:00',
        endTime: '17:00',
        days: [2, 4],
      );

      final conflicts = ScheduleConflictDetector.findConflicts(
        candidate: sched2,
        existingList: [sched1],
      );

      expect(conflicts.length, 1);
      expect(conflicts.first.overlappingDays, [2]);
      expect(conflicts.first.summary, contains('Tue'));
    });

    test('validates time format and empty days', () async {
      await controller.load();
      final invalidTime = controller.createDraft(PolicyScheduleType.custom).copyWith(
        startTime: '25:99',
      );
      final res1 = await controller.saveSchedule(invalidTime);
      expect(res1, isFalse);
      expect(controller.errorMessage.value, contains('HH:mm'));

      final noDays = controller.createDraft(PolicyScheduleType.custom).copyWith(
        days: [],
      );
      final res2 = await controller.saveSchedule(noDays);
      expect(res2, isFalse);
      expect(controller.errorMessage.value, contains('active day'));
    });
  });
}
