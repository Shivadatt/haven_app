import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

void main() {
  group('Sub-step 2.4 - PolicyEvaluator 7-Level Precedence Cascade', () {
    final fixedDate = DateTime(2026, 11, 18, 12, 0);

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
        snapshotDate: fixedDate,
        snapshotTime: fixedDate,
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

    test('Level 1: blockedApps is absolute hard veto over emergency, limits, and whitelist', () {
      final context = PolicyEvaluationContext(
        config: makeConfig(
          dailyScreenTimeMinutes: 120,
          blockedApps: ['com.google.android.dialer', 'com.example.game'],
          allowedApps: ['com.example.game'],
          appLimits: {'com.google.android.dialer': 60, 'com.example.game': 30},
        ),
        evaluationTime: fixedDate,
      );
      final usage = makeUsage(totalMinutes: 10, appMinutes: {'com.example.game': 5});

      final result = PolicyEvaluator.evaluate(
        context: context,
        usage: usage,
        targetPackages: ['com.google.android.dialer', 'com.example.game'],
      );

      final emergencyEval = result.appEvaluations['com.google.android.dialer']!;
      expect(emergencyEval.status, AppPolicyStatus.blockedByParent);
      expect(emergencyEval.reason, 'Blocked by parent');

      final whitelistedEval = result.appEvaluations['com.example.game']!;
      expect(whitelistedEval.status, AppPolicyStatus.blockedByParent);
      expect(whitelistedEval.reason, 'Blocked by parent');
    });

    test('Level 2 & Decision 2.28: Emergency packages bypass schedules, app limits, and quota', () {
      final context = PolicyEvaluationContext(
        config: makeConfig(
          dailyScreenTimeMinutes: 60,
          schedules: [
            PolicySchedule(
              id: 'bed_1',
              name: 'Bedtime',
              type: PolicyScheduleType.bedtime,
              startTime: '10:00',
              endTime: '14:00',
              days: [fixedDate.weekday],
              allowedApps: const [],
            ),
          ],
          appLimits: {'com.google.android.dialer': 10},
        ),
        evaluationTime: fixedDate,
      );
      final usage = makeUsage(totalMinutes: 120, appMinutes: {'com.google.android.dialer': 30});

      final result = PolicyEvaluator.evaluate(
        context: context,
        usage: usage,
        targetPackages: ['com.google.android.dialer', 'com.other.app'],
      );

      final dialerEval = result.appEvaluations['com.google.android.dialer']!;
      expect(dialerEval.status, AppPolicyStatus.exempt);
      expect(dialerEval.reason, 'Emergency service');

      final otherEval = result.appEvaluations['com.other.app']!;
      expect(otherEval.status, AppPolicyStatus.scheduleRestricted);
    });

    test('Level 3: Active schedule restricts non-excepted apps even if under limits', () {
      final context = PolicyEvaluationContext(
        config: makeConfig(
          dailyScreenTimeMinutes: 120,
          schedules: [
            PolicySchedule(
              id: 'school_1',
              name: 'School',
              type: PolicyScheduleType.school,
              startTime: '08:00',
              endTime: '15:00',
              days: [fixedDate.weekday],
              allowedApps: const ['com.calculator'],
            ),
          ],
          appLimits: {'com.calculator': 60, 'com.game': 60},
        ),
        evaluationTime: fixedDate,
      );
      final usage = makeUsage(totalMinutes: 10, appMinutes: {'com.calculator': 5, 'com.game': 5});

      final result = PolicyEvaluator.evaluate(
        context: context,
        usage: usage,
        targetPackages: ['com.calculator', 'com.game'],
      );

      expect(result.appEvaluations['com.calculator']!.status, AppPolicyStatus.scheduleAllowed);
      expect(result.appEvaluations['com.game']!.status, AppPolicyStatus.scheduleRestricted);
    });

    test('Level 4: Explicit per-app limits take precedence over global daily quota', () {
      final context = PolicyEvaluationContext(
        config: makeConfig(
          dailyScreenTimeMinutes: 120,
          appLimits: {'com.game': 30},
        ),
        evaluationTime: fixedDate,
      );
      final usage = makeUsage(totalMinutes: 40, appMinutes: {'com.game': 35});

      final result = PolicyEvaluator.evaluate(
        context: context,
        usage: usage,
        targetPackages: ['com.game'],
      );

      final eval = result.appEvaluations['com.game']!;
      expect(eval.status, AppPolicyStatus.appLimitReached);
      expect(eval.reason, 'App limit reached');
      expect(eval.remainingMinutes, 0);
    });

    test('Level 5 & 6: Daily quota reached blocks normal apps but parent whitelist is exempt', () {
      final context = PolicyEvaluationContext(
        config: makeConfig(
          dailyScreenTimeMinutes: 60,
          allowedApps: ['com.educational.reader'],
        ),
        evaluationTime: fixedDate,
      );
      final usage = makeUsage(
        totalMinutes: 75,
        appMinutes: {'com.educational.reader': 20, 'com.game': 55},
      );

      final result = PolicyEvaluator.evaluate(
        context: context,
        usage: usage,
        targetPackages: ['com.educational.reader', 'com.game', 'com.other'],
      );

      expect(result.appEvaluations['com.educational.reader']!.status, AppPolicyStatus.allowed);
      expect(result.appEvaluations['com.educational.reader']!.reason, 'Parent whitelist exempt');

      expect(result.appEvaluations['com.game']!.status, AppPolicyStatus.dailyLimitReached);
      expect(result.appEvaluations['com.other']!.status, AppPolicyStatus.dailyLimitReached);
    });
  });
}
