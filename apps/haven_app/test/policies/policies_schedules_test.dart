import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/policies/controllers/policies_controller.dart';
import 'package:haven_app/features/policies/data/policy_schedules.dart';

import 'fakes.dart';

void main() {
  group('Schedules Policy Creation, Editing, and Day Selection', () {
    test('time format validation checks HH:mm correctly', () {
      expect(PolicySchedule.isValidTime('21:00'), isTrue);
      expect(PolicySchedule.isValidTime('00:00'), isTrue);
      expect(PolicySchedule.isValidTime('23:59'), isTrue);
      expect(PolicySchedule.isValidTime('24:00'), isFalse);
      expect(PolicySchedule.isValidTime('12:60'), isFalse);
      expect(PolicySchedule.isValidTime('bad'), isFalse);
    });

    test('creates new custom schedule and persists it', () async {
      final repo = FakePoliciesRepository(canConfigure: true);
      final controller = PoliciesController(repository: repo);
      controller.onInit();
      await pumpEventQueue();

      const newSched = PolicySchedule(
        id: 'sched-homework',
        name: 'Homework Focus',
        type: PolicyScheduleType.custom,
        startTime: '16:00',
        endTime: '18:00',
        days: [1, 2, 3, 4, 5],
        isActive: true,
      );

      final success = await controller.saveSchedule(newSched);
      expect(success, isTrue);
      expect(
        controller.config.value.schedules.any((s) => s.id == 'sched-homework'),
        isTrue,
      );
      expect(repo.saveCount, 1);
    });

    test('edits schedule time and day selection', () async {
      final repo = FakePoliciesRepository(canConfigure: true);
      final controller = PoliciesController(repository: repo);
      controller.onInit();
      await pumpEventQueue();

      final bedtime = controller.config.value.schedules.firstWhere(
        (s) => s.type == PolicyScheduleType.bedtime,
      );
      final edited = bedtime.copyWith(
        startTime: '22:30',
        endTime: '06:30',
        days: [1, 2, 3, 4, 5], // weekdays only
      );

      await controller.saveSchedule(edited);

      final updated = controller.config.value.schedules.firstWhere(
        (s) => s.id == bedtime.id,
      );
      expect(updated.startTime, '22:30');
      expect(updated.endTime, '06:30');
      expect(updated.days, [1, 2, 3, 4, 5]);
      expect(updated.formattedDays, 'Weekdays');
    });

    test('toggles schedule active state', () async {
      final repo = FakePoliciesRepository(canConfigure: true);
      final controller = PoliciesController(repository: repo);
      controller.onInit();
      await pumpEventQueue();

      final school = controller.config.value.schedules.firstWhere(
        (s) => s.type == PolicyScheduleType.school,
      );
      expect(school.isActive, isTrue);

      await controller.toggleSchedule(school.id);
      final toggled = controller.config.value.schedules.firstWhere(
        (s) => s.id == school.id,
      );
      expect(toggled.isActive, isFalse);
    });

    test('deletes schedule by id', () async {
      final repo = FakePoliciesRepository(canConfigure: true);
      final controller = PoliciesController(repository: repo);
      controller.onInit();
      await pumpEventQueue();

      final initialCount = controller.config.value.schedules.length;
      final toRemove = controller.config.value.schedules.first.id;

      await controller.deleteSchedule(toRemove);
      expect(controller.config.value.schedules.length, initialCount - 1);
      expect(
        controller.config.value.schedules.any((s) => s.id == toRemove),
        isFalse,
      );
    });
  });
}
