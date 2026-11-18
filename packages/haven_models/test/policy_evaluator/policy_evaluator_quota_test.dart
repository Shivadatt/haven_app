import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

void main() {
  group('Sub-step 2.4 - PolicyEvaluator Quota, Rollover, and Decisions', () {
    final fixedNoon = DateTime(2026, 11, 18, 12, 0);

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
      DateTime? date,
      int totalMinutes = 0,
      Map<String, int> appMinutes = const {},
    }) {
      final d = date ?? fixedNoon;
      return PolicyUsageSnapshot(
        snapshotDate: d,
        snapshotTime: d,
        startInterval: DateTime(d.year, d.month, d.day, 0, 0),
        endInterval: DateTime(d.year, d.month, d.day, 23, 59),
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

    test('Daily quota metrics: unlimited, reached, exceeded, and 0 limit', () {
      final ctxUnlimited = PolicyEvaluationContext.withUnlimitedQuota(
        config: makeConfig(),
        evaluationTime: fixedNoon,
      );
      final usage = makeUsage(totalMinutes: 60);
      final resUnlimited = PolicyEvaluator.evaluate(context: ctxUnlimited, usage: usage);
      expect(resUnlimited.dailyQuota.isUnlimited, isTrue);
      expect(resUnlimited.dailyQuota.isReached, isFalse);

      final ctxZero = PolicyEvaluationContext(
        config: makeConfig(dailyScreenTimeMinutes: 0),
        evaluationTime: fixedNoon,
      );
      final resZero = PolicyEvaluator.evaluate(context: ctxZero, usage: usage);
      expect(resZero.dailyQuota.isReached, isTrue);
      expect(resZero.dailyQuota.remainingMinutes, 0);
    });

    test('Tri-state daily quota override precedence', () {
      final ctxOverridden = PolicyEvaluationContext.withQuotaOverride(
        config: makeConfig(dailyScreenTimeMinutes: 60),
        evaluationTime: fixedNoon,
        minutes: 180, // Override wins over base 60
      );
      expect(ctxOverridden.effectiveDailyLimit, 180);

      final usage = makeUsage(totalMinutes: 90);
      final res = PolicyEvaluator.evaluate(context: ctxOverridden, usage: usage);
      expect(res.dailyQuota.limitMinutes, 180);
      expect(res.dailyQuota.isReached, isFalse);
      expect(res.dailyQuota.remainingMinutes, 90);
    });

    test('Decision 2.29: Local date mismatch invalidates usage fail-safe without false blocking', () {
      final yesterdaySnapshot = DateTime(2026, 11, 17, 12, 0);

      final context = PolicyEvaluationContext(
        config: makeConfig(
          dailyScreenTimeMinutes: 60,
          appLimits: {'com.game': 30},
        ),
        evaluationTime: fixedNoon,
      );
      final staleUsage = makeUsage(
        date: yesterdaySnapshot,
        totalMinutes: 120,
        appMinutes: {'com.game': 50},
      );

      final result = PolicyEvaluator.evaluate(
        context: context,
        usage: staleUsage,
        targetPackages: ['com.game'],
      );

      expect(result.dailyQuota.isUnavailable, isTrue);
      expect(result.appEvaluations['com.game']!.status, AppPolicyStatus.allowed);
      expect(result.secondaryReasons, contains('Usage data unavailable'));
    });

    test('Decision 2.26: Target packages dynamic union vs explicit authoritative subset', () {
      final context = PolicyEvaluationContext(
        config: makeConfig(
          blockedApps: ['com.blocked'],
          allowedApps: ['com.allowed'],
          appLimits: {'com.limited': 30},
        ),
        evaluationTime: fixedNoon,
      );
      final usage = makeUsage(
        totalMinutes: 0,
        appMinutes: {'com.active': 1},
      );

      final dynamicResult = PolicyEvaluator.evaluate(context: context, usage: usage);
      expect(
        dynamicResult.appEvaluations.keys.toSet(),
        containsAll({'com.blocked', 'com.allowed', 'com.limited', 'com.active'}),
      );

      final explicitResult = PolicyEvaluator.evaluate(
        context: context,
        usage: usage,
        targetPackages: ['com.blocked'],
      );
      expect(explicitResult.appEvaluations.keys, equals(['com.blocked']));
    });

    test('Decision 2.27: Schedule visual priority and Decision 2.30 determinism', () {
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
              days: [fixedNoon.weekday],
              allowedApps: const [],
            ),
          ],
        ),
        evaluationTime: fixedNoon,
      );
      final usage = makeUsage(totalMinutes: 100);

      final r1 = PolicyEvaluator.evaluate(context: context, usage: usage);
      final r2 = PolicyEvaluator.evaluate(context: context, usage: usage);

      expect(r1.overallState, PolicyOverallState.bedtimeActive);
      expect(r1.primaryReason, 'Bedtime active');
      expect(r1.secondaryReasons, contains('Daily screen time limit exceeded'));
      expect(r1.dailyQuota.isExceeded, isTrue);

      expect(r1.overallState, r2.overallState);
      expect(r1.primaryReason, r2.primaryReason);
      expect(r1.dailyQuota.usedMinutes, r2.dailyQuota.usedMinutes);
      expect(r1.appEvaluations.length, r2.appEvaluations.length);
    });
  });
}
