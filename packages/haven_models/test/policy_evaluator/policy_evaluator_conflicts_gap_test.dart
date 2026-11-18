import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

void main() {
  group('Sub-step 2.4.1 - Conflicts Gap Closure (C-02, C-07, C-14, C-16, C-18)', () {
    final fixedTime = DateTime(2026, 11, 18, 12, 0); // Wednesday noon

    PolicyConfig makeConfig({
      int dailyScreenTimeMinutes = 120,
      List<PolicySchedule> schedules = const [],
      List<String> allowedApps = const [],
      List<String> blockedApps = const [],
      Map<String, int> appLimits = const {},
    }) =>
        PolicyConfig(
          dailyScreenTimeMinutes: dailyScreenTimeMinutes,
          schedules: schedules,
          allowedApps: allowedApps,
          blockedApps: blockedApps,
          appLimits: appLimits,
          allowedDomains: const [],
          blockedDomains: const [],
        );

    PolicyUsageSnapshot makeUsage({
      int totalMinutes = 0,
      Map<String, int> appMinutes = const {},
    }) {
      return PolicyUsageSnapshot(
        snapshotDate: fixedTime,
        snapshotTime: fixedTime,
        startInterval: DateTime(2026, 11, 18, 0, 0),
        endInterval: DateTime(2026, 11, 18, 23, 59),
        totalForegroundMillis: totalMinutes * 60 * 1000,
        appForegroundMillis: {
          for (final entry in appMinutes.entries)
            entry.key: entry.value * 60 * 1000,
        },
        completeness: PolicyUsageCompleteness.complete,
        freshness: PolicyUsageFreshness.recent,
        isPermissionGranted: true,
      );
    }

    test('C-02: Parent blocklist overrides schedule whitelist', () {
      final context = PolicyEvaluationContext(
        config: makeConfig(
          blockedApps: ['com.school.math'],
          schedules: [
            PolicySchedule(
              id: 'sch_1',
              name: 'School',
              type: PolicyScheduleType.school,
              startTime: '08:00',
              endTime: '15:00',
              days: [fixedTime.weekday],
              allowedApps: const ['com.school.math'],
            ),
          ],
        ),
        evaluationTime: fixedTime,
      );

      final result = PolicyEvaluator.evaluate(
        context: context,
        usage: makeUsage(),
        targetPackages: ['com.school.math'],
      );

      final eval = result.appEvaluations['com.school.math']!;
      expect(eval.status, AppPolicyStatus.blockedByParent);
      expect(eval.reason, 'Blocked by parent');
    });

    test('C-07: Emergency default bypasses active school schedule unless blocklisted', () {
      final context = PolicyEvaluationContext(
        config: makeConfig(
          schedules: [
            PolicySchedule(
              id: 'sch_1',
              name: 'School',
              type: PolicyScheduleType.school,
              startTime: '08:00',
              endTime: '15:00',
              days: [fixedTime.weekday],
              allowedApps: const ['com.calculator'],
            ),
          ],
        ),
        evaluationTime: fixedTime,
      );

      final result = PolicyEvaluator.evaluate(
        context: context,
        usage: makeUsage(),
        targetPackages: ['com.google.android.dialer', 'com.other.app'],
      );

      expect(result.appEvaluations['com.google.android.dialer']!.status, AppPolicyStatus.exempt);
      expect(result.appEvaluations['com.google.android.dialer']!.reason, 'Emergency service');
      expect(result.appEvaluations['com.other.app']!.status, AppPolicyStatus.scheduleRestricted);

      final blockedCtx = PolicyEvaluationContext(
        config: makeConfig(
          blockedApps: ['com.google.android.dialer'],
          schedules: context.config.schedules,
        ),
        evaluationTime: fixedTime,
      );
      final blockedRes = PolicyEvaluator.evaluate(
        context: blockedCtx,
        usage: makeUsage(),
        targetPackages: ['com.google.android.dialer'],
      );
      expect(blockedRes.appEvaluations['com.google.android.dialer']!.status, AppPolicyStatus.blockedByParent);
    });

    test('C-14: Parent whitelist does not bypass per-app limits', () {
      final context = PolicyEvaluationContext(
        config: makeConfig(
          allowedApps: ['com.whitelisted.reader'],
          appLimits: {'com.whitelisted.reader': 30},
        ),
        evaluationTime: fixedTime,
      );
      final usage = makeUsage(appMinutes: {'com.whitelisted.reader': 35});

      final result = PolicyEvaluator.evaluate(
        context: context,
        usage: usage,
        targetPackages: ['com.whitelisted.reader'],
      );

      final eval = result.appEvaluations['com.whitelisted.reader']!;
      expect(eval.status, AppPolicyStatus.appLimitReached);
      expect(eval.reason, 'App limit reached');
      expect(eval.remainingMinutes, 0);
    });

    test('C-16: Parent whitelist does not bypass active bedtime schedule', () {
      final context = PolicyEvaluationContext(
        config: makeConfig(
          allowedApps: ['com.whitelisted.reader'],
          schedules: [
            PolicySchedule(
              id: 'bed_1',
              name: 'Bedtime',
              type: PolicyScheduleType.bedtime,
              startTime: '10:00',
              endTime: '14:00',
              days: [fixedTime.weekday],
              allowedApps: const [],
            ),
          ],
        ),
        evaluationTime: fixedTime,
      );

      final result = PolicyEvaluator.evaluate(
        context: context,
        usage: makeUsage(),
        targetPackages: ['com.whitelisted.reader'],
      );

      final eval = result.appEvaluations['com.whitelisted.reader']!;
      expect(eval.status, AppPolicyStatus.scheduleRestricted);
      expect(eval.reason, 'Bedtime active');
      expect(result.overallState, PolicyOverallState.bedtimeActive);
    });

    test('C-18: Daily quota reached with per-app limit remaining', () {
      final context = PolicyEvaluationContext(
        config: makeConfig(
          dailyScreenTimeMinutes: 60,
          appLimits: {'com.game': 100},
        ),
        evaluationTime: fixedTime,
      );
      final usage = makeUsage(totalMinutes: 70, appMinutes: {'com.game': 30});

      final result = PolicyEvaluator.evaluate(
        context: context,
        usage: usage,
        targetPackages: ['com.game'],
      );

      final eval = result.appEvaluations['com.game']!;
      expect(eval.status, AppPolicyStatus.dailyLimitReached);
      expect(eval.reason, 'Daily limit reached');
      expect(eval.limitMinutes, 100);
      expect(eval.usedMinutes, 30);
      expect(eval.remainingMinutes, 70);
      expect(result.overallState, PolicyOverallState.dailyLimitExceeded);
    });
  });
}
