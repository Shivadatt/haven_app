import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

void main() {
  group('ScheduleEvaluator - Interval and Boundary Evaluation', () {
    final schoolSchedule = PolicySchedule(
      id: 'sched-school',
      name: 'School Hours',
      type: PolicyScheduleType.school,
      startTime: '08:00',
      endTime: '15:00',
      days: const [1, 2, 3, 4, 5],
    );

    final bedtimeSchedule = PolicySchedule(
      id: 'sched-bedtime',
      name: 'Bedtime',
      type: PolicyScheduleType.bedtime,
      startTime: '21:00',
      endTime: '07:00',
      days: const [1, 2, 3, 4, 5, 6, 7],
    );

    test('1. Normal same-day schedule activation within bounds', () {
      final t = DateTime(2026, 11, 16, 10, 30); // Monday 10:30
      expect(ScheduleEvaluator.isScheduleActive(schoolSchedule, t), isTrue);
    });

    test('2. Start boundary is inclusive [start, end)', () {
      final t = DateTime(2026, 11, 16, 8, 0); // Monday 08:00
      expect(ScheduleEvaluator.isScheduleActive(schoolSchedule, t), isTrue);
    });

    test('3. End boundary is exclusive [start, end)', () {
      final t = DateTime(2026, 11, 16, 15, 0); // Monday 15:00
      expect(ScheduleEvaluator.isScheduleActive(schoolSchedule, t), isFalse);
    });

    test('4. Seconds and milliseconds ignored (minute precision)', () {
      final tStart = DateTime(2026, 11, 16, 8, 0, 59, 999);
      final tBeforeEnd = DateTime(2026, 11, 16, 14, 59, 59, 999);
      expect(
        ScheduleEvaluator.isScheduleActive(schoolSchedule, tStart),
        isTrue,
      );
      expect(
        ScheduleEvaluator.isScheduleActive(schoolSchedule, tBeforeEnd),
        isTrue,
      );
    });

    test('5. Overnight schedule evening segment on same day', () {
      final t = DateTime(2026, 11, 16, 21, 30); // Monday 21:30
      expect(ScheduleEvaluator.isScheduleActive(bedtimeSchedule, t), isTrue);
    });

    test('6. Overnight schedule morning segment next day', () {
      final t = DateTime(2026, 11, 17, 6, 30); // Tuesday 06:30
      expect(ScheduleEvaluator.isScheduleActive(bedtimeSchedule, t), isTrue);
    });

    test('7. Overnight previous weekday ownership verification', () {
      final monOnlyBedtime = PolicySchedule(
        id: 'sched-mon-bedtime',
        name: 'Mon Bedtime',
        type: PolicyScheduleType.bedtime,
        startTime: '21:00',
        endTime: '07:00',
        days: const [1], // Monday only
      );
      // Tuesday morning (owned by Monday night) -> active
      final tTueMorning = DateTime(2026, 11, 17, 6, 0);
      expect(
        ScheduleEvaluator.isScheduleActive(monOnlyBedtime, tTueMorning),
        isTrue,
      );
      // Wednesday morning (Tuesday night not active) -> inactive
      final tWedMorning = DateTime(2026, 11, 18, 6, 0);
      expect(
        ScheduleEvaluator.isScheduleActive(monOnlyBedtime, tWedMorning),
        isFalse,
      );
    });

    test('8. Sunday-to-Monday rollover (previousDay = 7 for weekday 1)', () {
      final sunOnlyBedtime = PolicySchedule(
        id: 'sched-sun-bedtime',
        name: 'Sun Bedtime',
        type: PolicyScheduleType.bedtime,
        startTime: '21:00',
        endTime: '07:00',
        days: const [7], // Sunday only
      );
      // Monday 05:00 is rolled over from Sunday night
      final tMonMorning = DateTime(2026, 11, 16, 5, 0); // Monday 05:00
      expect(
        ScheduleEvaluator.isScheduleActive(sunOnlyBedtime, tMonMorning),
        isTrue,
      );
    });

    test('9. Equal start and end is zero-duration and inactive', () {
      final zeroDuration = PolicySchedule(
        id: 'sched-zero',
        name: 'Zero Duration',
        type: PolicyScheduleType.custom,
        startTime: '12:00',
        endTime: '12:00',
        days: const [1, 2, 3, 4, 5, 6, 7],
      );
      final t = DateTime(2026, 11, 16, 12, 0);
      expect(ScheduleEvaluator.isScheduleActive(zeroDuration, t), isFalse);
    });

    test('10. Empty weekdays list never activates', () {
      final emptyDays = PolicySchedule(
        id: 'sched-empty',
        name: 'Empty Days',
        type: PolicyScheduleType.custom,
        startTime: '08:00',
        endTime: '15:00',
        days: const [],
      );
      final t = DateTime(2026, 11, 16, 10, 0);
      expect(ScheduleEvaluator.isScheduleActive(emptyDays, t), isFalse);
    });

    test('11. Any invalid weekday entry makes entire schedule inactive', () {
      final invalidDays = PolicySchedule(
        id: 'sched-invalid-days',
        name: 'Invalid Days',
        type: PolicyScheduleType.custom,
        startTime: '08:00',
        endTime: '15:00',
        days: const [1, 8], // 8 is out of bounds
      );
      final t = DateTime(2026, 11, 16, 10, 0); // Monday 10:00
      expect(ScheduleEvaluator.isScheduleActive(invalidDays, t), isFalse);
    });

    test('12. Malformed start/end time strings safely return inactive', () {
      final malformed = PolicySchedule(
        id: 'sched-bad-time',
        name: 'Bad Time',
        type: PolicyScheduleType.custom,
        startTime: 'invalid',
        endTime: '15:00',
        days: const [1, 2, 3, 4, 5],
      );
      final t = DateTime(2026, 11, 16, 10, 0);
      expect(ScheduleEvaluator.isScheduleActive(malformed, t), isFalse);
    });

    test('13. Disabled schedule is ignored', () {
      final disabled = PolicySchedule(
        id: 'sched-disabled',
        name: 'Disabled School',
        type: PolicyScheduleType.school,
        startTime: '08:00',
        endTime: '15:00',
        days: const [1, 2, 3, 4, 5],
        isActive: false,
      );
      final t = DateTime(2026, 11, 16, 10, 0);
      expect(ScheduleEvaluator.isScheduleActive(disabled, t), isFalse);
    });
  });
}
