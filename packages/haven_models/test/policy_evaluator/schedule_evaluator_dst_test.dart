import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

void main() {
  group('ScheduleEvaluator - Daylight Saving Time (DST) & Wall-Clock Edge Cases', () {
    final bedtime = PolicySchedule(
      id: 'sched-bedtime',
      name: 'Bedtime',
      type: PolicyScheduleType.bedtime,
      startTime: '21:00',
      endTime: '07:00',
      days: const [1, 2, 3, 4, 5, 6, 7],
      allowedApps: const [],
    );

    final lateNightSchedule = PolicySchedule(
      id: 'sched-late-night',
      name: 'Late Night Study',
      type: PolicyScheduleType.custom,
      startTime: '01:00',
      endTime: '03:00',
      days: const [1, 2, 3, 4, 5, 6, 7],
      allowedApps: const ['com.study.app'],
    );

    final morningSchedule = PolicySchedule(
      id: 'sched-morning',
      name: 'Early Morning',
      type: PolicyScheduleType.custom,
      startTime: '03:00',
      endTime: '06:00',
      days: const [1, 2, 3, 4, 5, 6, 7],
    );

    test('1. Spring Forward (23-hour day): overnight schedule remains active before skip', () {
      final tBefore = DateTime(2026, 3, 29, 1, 45);
      expect(ScheduleEvaluator.isScheduleActive(bedtime, tBefore), isTrue);
      expect(ScheduleEvaluator.isScheduleActive(lateNightSchedule, tBefore), isTrue);
    });

    test('2. Spring Forward (23-hour day): overnight schedule remains active after skip', () {
      final tAfter = DateTime(2026, 3, 29, 3, 15);
      expect(ScheduleEvaluator.isScheduleActive(bedtime, tAfter), isTrue);
      expect(ScheduleEvaluator.isScheduleActive(morningSchedule, tAfter), isTrue);
      expect(ScheduleEvaluator.isScheduleActive(lateNightSchedule, tAfter), isFalse);
    });

    test('3. Fall Back (25-hour day): repeated hour maintains deterministic evaluation', () {
      final tRepeated = DateTime(2026, 10, 25, 1, 30);
      expect(ScheduleEvaluator.isScheduleActive(bedtime, tRepeated), isTrue);
      expect(ScheduleEvaluator.isScheduleActive(lateNightSchedule, tRepeated), isTrue);
      expect(ScheduleEvaluator.isScheduleActive(morningSchedule, tRepeated), isFalse);
    });

    test('4. Fall Back (25-hour day): hour boundary transition at 03:00 wall clock', () {
      final tJustBefore3 = DateTime(2026, 10, 25, 2, 59, 59);
      final tAt3 = DateTime(2026, 10, 25, 3, 0);

      // lateNightSchedule [01:00, 03:00) is active until 02:59 and inactive at 03:00
      expect(ScheduleEvaluator.isScheduleActive(lateNightSchedule, tJustBefore3), isTrue);
      expect(ScheduleEvaluator.isScheduleActive(lateNightSchedule, tAt3), isFalse);
      expect(ScheduleEvaluator.isScheduleActive(morningSchedule, tAt3), isTrue);
      expect(ScheduleEvaluator.isScheduleActive(bedtime, tAt3), isTrue);
    });

    test('5. Multi-schedule evaluation during DST transition maintains lockdown', () {
      final tDstNight = DateTime(2026, 3, 29, 3, 30);
      final res = ScheduleEvaluator.evaluate(
        schedules: [bedtime, morningSchedule],
        evaluationTime: tDstNight,
      );

      expect(res.isAnyScheduleActive, isTrue);
      expect(res.isBedtimeActive, isTrue);
      expect(res.allowedAppExceptions, isEmpty);
      expect(res.isAppAllowed('com.study.app'), isFalse);
    });

    test('6. PolicyEvaluator integrates DST schedule evaluation correctly', () {
      final tDstNight = DateTime(2026, 3, 29, 3, 30);
      final config = PolicyConfig(
        dailyScreenTimeMinutes: 120,
        schedules: [bedtime],
        allowedApps: const [],
        blockedApps: const [],
        appLimits: const {},
        allowedDomains: const [],
        blockedDomains: const [],
      );

      final context = PolicyEvaluationContext(
        config: config,
        evaluationTime: tDstNight,
      );

      final usage = PolicyUsageSnapshot.empty(
        snapshotDate: tDstNight,
        snapshotTime: tDstNight,
        startInterval: DateTime(2026, 3, 29, 0, 0),
        endInterval: DateTime(2026, 3, 29, 23, 59),
        isPermissionGranted: true,
        completeness: PolicyUsageCompleteness.complete,
        freshness: PolicyUsageFreshness.recent,
      );

      final result = PolicyEvaluator.evaluate(
        context: context,
        usage: usage,
        targetPackages: const ['com.android.phone', 'com.instagram.android'],
      );

      expect(result.overallState, equals(PolicyOverallState.bedtimeActive));
      expect(result.primaryReason, equals('Bedtime active'));

      // Emergency package exempt from bedtime during DST (Decisions 2.2 & 2.12)
      final phone = result.appEvaluations['com.android.phone']!;
      expect(phone.status, equals(AppPolicyStatus.exempt));
      expect(phone.isRestricted, isFalse);

      // Non-emergency restricted by bedtime during DST
      final insta = result.appEvaluations['com.instagram.android']!;
      expect(insta.status, equals(AppPolicyStatus.scheduleRestricted));
      expect(insta.isRestricted, isTrue);
    });

    test('7. UTC timestamp converted via toLocal evaluates wall-clock without drift', () {
      final localTime = DateTime(2026, 10, 25, 1, 30);
      final utcTime = localTime.toUtc();

      final resLocal = ScheduleEvaluator.evaluate(
        schedules: [bedtime],
        evaluationTime: localTime,
      );
      final resUtc = ScheduleEvaluator.evaluate(
        schedules: [bedtime],
        evaluationTime: utcTime,
      );

      expect(resUtc.isAnyScheduleActive, equals(resLocal.isAnyScheduleActive));
      expect(resUtc.isBedtimeActive, equals(resLocal.isBedtimeActive));
      expect(resUtc.allowedAppExceptions, equals(resLocal.allowedAppExceptions));
    });
  });
}
