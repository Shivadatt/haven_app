import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

void main() {
  group('Sub-step 2.4 - Policy Evaluation Models', () {
    test('DailyQuotaEvaluation properties and flags', () {
      const quota = DailyQuotaEvaluation(
        limitMinutes: 120,
        usedMinutes: 130,
        remainingMinutes: 0,
        isReached: true,
        isExceeded: true,
        isUnavailable: false,
        isUnlimited: false,
      );
      expect(quota.limitMinutes, 120);
      expect(quota.usedMinutes, 130);
      expect(quota.remainingMinutes, 0);
      expect(quota.isReached, isTrue);
      expect(quota.isExceeded, isTrue);
      expect(quota.isUnavailable, isFalse);
      expect(quota.isUnlimited, isFalse);
    });

    test('AppEvaluation isRestricted logic', () {
      const restrictedStatuses = [
        AppPolicyStatus.blockedByParent,
        AppPolicyStatus.scheduleRestricted,
        AppPolicyStatus.appLimitReached,
        AppPolicyStatus.dailyLimitReached,
      ];
      for (final status in restrictedStatuses) {
        final eval = AppEvaluation(
          packageName: 'com.example.app',
          status: status,
          reason: 'Test',
          usedMinutes: 10,
        );
        expect(eval.isRestricted, isTrue, reason: 'Expected $status to be restricted');
      }

      const permittedStatuses = [
        AppPolicyStatus.exempt,
        AppPolicyStatus.allowed,
        AppPolicyStatus.scheduleAllowed,
        AppPolicyStatus.usageUnavailable,
      ];
      for (final status in permittedStatuses) {
        final eval = AppEvaluation(
          packageName: 'com.example.app',
          status: status,
          reason: 'Test',
          usedMinutes: 10,
        );
        expect(eval.isRestricted, isFalse, reason: 'Expected $status not to be restricted');
      }
    });

    test('PolicyEvaluationResult unmodifiable collections and disclosure', () {
      final mutableSchedules = <PolicySchedule>[];
      final mutableApps = <String, AppEvaluation>{};
      final mutableSecondary = <String>['Secondary notice'];

      final result = PolicyEvaluationResult(
        overallState: PolicyOverallState.allowed,
        evaluationTime: DateTime.utc(2026, 11, 18, 12, 0),
        activeSchedules: mutableSchedules,
        dailyQuota: const DailyQuotaEvaluation(
          limitMinutes: null,
          usedMinutes: null,
          remainingMinutes: null,
          isReached: false,
          isExceeded: false,
          isUnavailable: false,
          isUnlimited: true,
        ),
        appEvaluations: mutableApps,
        isDowntimeActive: false,
        primaryReason: 'All clear',
        secondaryReasons: mutableSecondary,
      );

      expect(
        result.disclosure,
        'Policies are evaluated locally. Application blocking is not enforced on this build.',
      );

      // Verify unmodifiable collections throw on mutation
      expect(
        () => result.activeSchedules.add(
          const PolicySchedule(
            id: 's1',
            name: 'Bedtime',
            type: PolicyScheduleType.bedtime,
            startTime: '21:00',
            endTime: '07:00',
            days: [1, 2, 3, 4, 5, 6, 7],
            allowedApps: [],
          ),
        ),
        throwsUnsupportedError,
      );

      expect(
        () => result.appEvaluations['test'] = const AppEvaluation(
          packageName: 'test',
          status: AppPolicyStatus.allowed,
          reason: 'r',
          usedMinutes: 0,
        ),
        throwsUnsupportedError,
      );

      expect(
        () => result.secondaryReasons.add('another'),
        throwsUnsupportedError,
      );
    });
  });
}
