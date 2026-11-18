import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

void main() {
  group('ScheduleEvaluator - Multi-Schedule & Whitelist Evaluation', () {
    final schoolSchedule = PolicySchedule(
      id: 'sched-school',
      name: 'School Hours',
      type: PolicyScheduleType.school,
      startTime: '08:00',
      endTime: '15:00',
      days: const [1, 2, 3, 4, 5],
      allowedApps: const ['com.google.android.calculator', 'com.google.docs'],
    );

    final studySchedule = PolicySchedule(
      id: 'sched-study',
      name: 'Study Focus',
      type: PolicyScheduleType.custom,
      startTime: '13:00',
      endTime: '16:00',
      days: const [1, 2, 3, 4, 5],
      allowedApps: const ['com.google.docs', 'com.dictionary'],
    );

    final bedtimeSchedule = PolicySchedule(
      id: 'sched-bedtime',
      name: 'Bedtime',
      type: PolicyScheduleType.bedtime,
      startTime: '21:00',
      endTime: '07:00',
      days: const [1, 2, 3, 4, 5, 6, 7],
      allowedApps: const [], // Default empty
    );

    test(
      '1. No active schedules returns inactive result without restriction',
      () {
        final t = DateTime(2026, 11, 15, 12, 0); // Sunday 12:00
        final res = ScheduleEvaluator.evaluate(
          schedules: [schoolSchedule],
          evaluationTime: t,
        );
        expect(res.isAnyScheduleActive, isFalse);
        expect(res.isBedtimeActive, isFalse);
        expect(res.isSchoolActive, isFalse);
        expect(res.activeSchedules, isEmpty);
        expect(res.allowedAppExceptions, isEmpty);
        expect(res.isAppAllowed('any.package'), isFalse);
      },
    );

    test('2. Two active schedules restrictive whitelist intersection', () {
      final t = DateTime(2026, 11, 16, 14, 0); // Monday 14:00 (overlaps both)
      final res = ScheduleEvaluator.evaluate(
        schedules: [schoolSchedule, studySchedule],
        evaluationTime: t,
      );
      expect(res.isAnyScheduleActive, isTrue);
      expect(res.isSchoolActive, isTrue);
      expect(res.activeSchedules.length, equals(2));
      expect(res.allowedAppExceptions, equals({'com.google.docs'}));
      expect(res.isAppAllowed('com.google.docs'), isTrue);
      expect(res.isAppAllowed('com.google.android.calculator'), isFalse);
    });

    test(
      '3. Bedtime lockdown protection forces empty whitelist intersection',
      () {
        final bedtimeEmpty = PolicySchedule(
          id: 'sched-bedtime-test',
          name: 'Bedtime',
          type: PolicyScheduleType.bedtime,
          startTime: '13:00',
          endTime: '16:00',
          days: const [1, 2, 3, 4, 5],
          allowedApps: const [], // Default empty
        );
        final t = DateTime(2026, 11, 16, 14, 0);
        final res = ScheduleEvaluator.evaluate(
          schedules: [schoolSchedule, bedtimeEmpty],
          evaluationTime: t,
        );
        expect(res.isAnyScheduleActive, isTrue);
        expect(res.isBedtimeActive, isTrue);
        expect(res.isSchoolActive, isTrue);
        expect(res.allowedAppExceptions, isEmpty);
      },
    );

    test(
      '4. Bedtime with configured allowedApps participates in intersection',
      () {
        final bedtimeWithApps = PolicySchedule(
          id: 'sched-bedtime-custom',
          name: 'Bedtime With White Noise',
          type: PolicyScheduleType.bedtime,
          startTime: '13:00',
          endTime: '16:00',
          days: const [1, 2, 3, 4, 5],
          allowedApps: const ['com.google.docs', 'com.whitenoise'],
        );
        final t = DateTime(2026, 11, 16, 14, 0);
        final res = ScheduleEvaluator.evaluate(
          schedules: [schoolSchedule, bedtimeWithApps],
          evaluationTime: t,
        );
        expect(res.isAnyScheduleActive, isTrue);
        expect(res.isBedtimeActive, isTrue);
        expect(res.allowedAppExceptions, equals({'com.google.docs'}));
        expect(res.isAppAllowed('com.google.docs'), isTrue);
        expect(res.isAppAllowed('com.whitenoise'), isFalse);
      },
    );

    test('5. Result collections are defensively unmodifiable', () {
      final t = DateTime(2026, 11, 16, 10, 0);
      final res = ScheduleEvaluator.evaluate(
        schedules: [schoolSchedule],
        evaluationTime: t,
      );
      expect(
        () => (res.activeSchedules as dynamic).add(schoolSchedule),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => (res.allowedAppExceptions as dynamic).add('test'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('6. UTC DateTime normalization matches local DateTime equivalent', () {
      final localInstant = DateTime(2026, 11, 16, 10, 0);
      final utcInstant = localInstant.toUtc();
      final localRes = ScheduleEvaluator.evaluate(
        schedules: [schoolSchedule],
        evaluationTime: localInstant,
      );
      final utcRes = ScheduleEvaluator.evaluate(
        schedules: [schoolSchedule],
        evaluationTime: utcInstant,
      );
      expect(utcRes.isAnyScheduleActive, equals(localRes.isAnyScheduleActive));
      expect(
        utcRes.allowedAppExceptions,
        equals(localRes.allowedAppExceptions),
      );
    });

    test('7. UTC input crossing weekday boundary matches local weekday', () {
      final baseInstant = DateTime(2026, 11, 16, 0, 15);
      final offset = baseInstant.timeZoneOffset;
      if (offset != Duration.zero) {
        final targetLocal = offset > Duration.zero
            ? baseInstant
            : DateTime(2026, 11, 16, 23, 45);
        final utcInstant = targetLocal.toUtc();
        expect(utcInstant.weekday, isNot(equals(targetLocal.weekday)));

        final mondaySchedule = PolicySchedule(
          id: 'sched-mon-crossover',
          name: 'Monday Full Day',
          type: PolicyScheduleType.custom,
          startTime: '00:00',
          endTime: '23:59',
          days: const [1],
        );
        expect(
          ScheduleEvaluator.isScheduleActive(mondaySchedule, utcInstant),
          isTrue,
        );
      } else {
        final utcInstant = DateTime.utc(2026, 11, 16, 10, 0);
        expect(
          ScheduleEvaluator.isScheduleActive(schoolSchedule, utcInstant),
          isTrue,
        );
      }
    });

    test('8. Deterministic repeated evaluation with zero clock drift', () {
      final t = DateTime(2026, 11, 16, 10, 0);
      final first = ScheduleEvaluator.evaluate(
        schedules: [schoolSchedule, bedtimeSchedule],
        evaluationTime: t,
      );
      for (var i = 0; i < 50; i++) {
        final current = ScheduleEvaluator.evaluate(
          schedules: [schoolSchedule, bedtimeSchedule],
          evaluationTime: t,
        );
        expect(current.isAnyScheduleActive, equals(first.isAnyScheduleActive));
        expect(
          current.allowedAppExceptions,
          equals(first.allowedAppExceptions),
        );
      }
    });
  });
}
