import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

void main() {
  group('Sub-step 2.4.1 - Telemetry Gap Closure (C-20 & Decision 2.16)', () {
    final fixedTime = DateTime(2026, 11, 18, 12, 0);

    PolicyConfig makeConfig({int dailyScreenTimeMinutes = 60}) =>
        PolicyConfig(
          dailyScreenTimeMinutes: dailyScreenTimeMinutes,
          schedules: const [],
          allowedApps: const [],
          blockedApps: const [],
          appLimits: const {},
          allowedDomains: const [],
          blockedDomains: const [],
        );

    PolicyUsageSnapshot makeUsage({
      int totalMinutes = 0,
      Map<String, int> appMinutes = const {},
      PolicyUsageCompleteness completeness = PolicyUsageCompleteness.complete,
      PolicyUsageFreshness freshness = PolicyUsageFreshness.recent,
      bool isPermissionGranted = true,
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
        completeness: completeness,
        freshness: freshness,
        isPermissionGranted: isPermissionGranted,
      );
    }

    test('C-20 & Decision 2.16: Delayed usage telemetry with missing package', () {
      final context = PolicyEvaluationContext(
        config: makeConfig(dailyScreenTimeMinutes: 60),
        evaluationTime: fixedTime,
      );
      final delayedUsage = makeUsage(
        totalMinutes: 20,
        freshness: PolicyUsageFreshness.delayed,
      );

      final result = PolicyEvaluator.evaluate(
        context: context,
        usage: delayedUsage,
        targetPackages: ['com.missing.app'],
      );

      final eval = result.appEvaluations['com.missing.app']!;
      expect(eval.usedMinutes, 0); // Missing package resolves to 0
      expect(eval.status, AppPolicyStatus.allowed);
      expect(result.isDelayed, isTrue);
      expect(result.secondaryReasons, contains('Usage data is delayed'));
      expect(result.dailyQuota.isReached, isFalse);
      expect(result.overallState, PolicyOverallState.allowed);
    });

    test('Decision 2.16: Unknown freshness resolves missing usage to 0 in evaluator', () {
      final context = PolicyEvaluationContext(
        config: makeConfig(dailyScreenTimeMinutes: 60),
        evaluationTime: fixedTime,
      );

      // Unknown freshness with complete + granted resolves missing app to 0
      final unknownUsage = makeUsage(
        totalMinutes: 10,
        freshness: PolicyUsageFreshness.unknown,
      );
      final unknownRes = PolicyEvaluator.evaluate(
        context: context,
        usage: unknownUsage,
        targetPackages: ['com.absent.app'],
      );
      expect(unknownRes.appEvaluations['com.absent.app']!.usedMinutes, 0);

      // Unavailable freshness invalidates usage, resolving missing app to null
      final unavailUsage = makeUsage(
        totalMinutes: 10,
        freshness: PolicyUsageFreshness.unavailable,
      );
      final unavailRes = PolicyEvaluator.evaluate(
        context: context,
        usage: unavailUsage,
        targetPackages: ['com.absent.app'],
      );
      expect(unavailRes.appEvaluations['com.absent.app']!.usedMinutes, isNull);
    });
  });
}
