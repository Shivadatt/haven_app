import 'package:flutter_test/flutter_test.dart';
import 'package:haven_child/core/native/usage_envelope_models.dart';
import 'package:haven_child/features/policies/controllers/child_policy_controller.dart';
import 'package:haven_child/features/policies/data/child_policy_record.dart';
import 'package:haven_child/features/policies/data/child_policy_repository.dart';
import 'package:haven_child/features/policies/data/policy_usage_adapter.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';
import '../child_usage/fake_child_usage_repository.dart';

void main() {
  final localMidnight = DateTime(2026, 11, 18);
  final noon = DateTime(2026, 11, 18, 12);
  late _FakePolicyRepository policyRepo;
  late FakeChildUsageRepository usageRepo;
  late FixedClock clock;
  late ChildPolicyController controller;
  setUp(() {
    policyRepo = _FakePolicyRepository();
    usageRepo = FakeChildUsageRepository();
    clock = FixedClock(noon);
    controller = ChildPolicyController(
      policyRepository: policyRepo,
      usageRepository: usageRepo,
      clock: clock,
    );
  });
  tearDown(() {
    if (!controller.isClosed) controller.onClose();
  });
  PolicyConfig config({
    int limit = 60,
    List<PolicySchedule> schedules = const [],
    List<String> blocked = const [],
  }) => PolicyConfig(
    dailyScreenTimeMinutes: limit,
    schedules: schedules,
    allowedApps: const [],
    blockedApps: blocked,
    appLimits: const {},
    allowedDomains: const [],
    blockedDomains: const [],
    safeSearchEnabled: false,
  );
  ChildPolicyRecord synced(PolicyConfig value) =>
      ChildPolicyRecord.parentSynced(
        config: value,
        policyVersion: 1,
        updatedAt: DateTime.utc(2026, 11, 18),
      );
  UsageDailyResult usage(List<UsageAppRecord> apps) {
    final range = PolicyUsageAdapter.dailyRange(clock.now());
    return UsageDailyResult(
      apiLevel: 34,
      startTimeMillis: range.start,
      endTimeMillis: range.end,
      totalForegroundMillis: apps.fold(
        0,
        (sum, app) => sum + app.totalForegroundMillis,
      ),
      dataFreshness: UsageDataFreshness.recent,
      apps: apps,
    );
  }

  UsageAppRecord app(String name, [int millis = 120000]) => UsageAppRecord(
    packageName: name,
    totalForegroundMillis: millis,
    isSystemApp: false,
  );
  test(
    'query failures become unavailable usage and retain exact failures',
    () async {
      policyRepo.result = Ok(synced(config()));
      await controller.loadPolicy();
      final permissionFailure = DevicePermissionFailure('revoked');
      usageRepo.dailyUsageResult = Err(permissionFailure);
      final first = await controller.evaluate();
      expect(first.isOk, isTrue);
      expect(first.valueOrNull?.dailyQuota.isUnavailable, isTrue);
      expect(controller.lastUsageFailure, same(permissionFailure));
      expect(
        controller.lastUsagePermissionStatus,
        UsagePermissionStatus.granted,
      );
      final other = BackendFailure('read failed', code: 'section_failed');
      usageRepo.dailyUsageResult = Err(other);
      await controller.evaluate();
      expect(controller.lastUsageFailure, same(other));
      expect(
        controller.lastUsagePermissionStatus,
        UsagePermissionStatus.granted,
      );
      usageRepo.dailyUsageResult = Ok(usage([app('com.a')]));
      await controller.evaluate();
      usageRepo.dailyUsageResult = Ok(usage([app('com.b')]));
      await controller.evaluate();
      expect(usageRepo.getDailyCalls, 4);
      expect(controller.lastUsageFailure, isNull);
      expect(
        controller.lastEvaluation.value?.appEvaluations['com.b'],
        isNotNull,
      );
    },
  );
  test(
    'exact local midnight skips query and keeps unavailable usage',
    () async {
      clock.setTo(localMidnight);
      policyRepo.result = Ok(
        synced(
          config(
            schedules: [
              PolicySchedule(
                id: 'midnight',
                name: 'Midnight',
                type: PolicyScheduleType.custom,
                startTime: '00:00',
                endTime: '01:00',
                days: [localMidnight.weekday],
              ),
            ],
            blocked: ['com.blocked'],
          ),
        ),
      );
      await controller.loadPolicy();
      final range = PolicyUsageAdapter.dailyRange(clock.now());
      expect(range.start, range.end);
      final result = await controller.evaluate();
      expect(usageRepo.getPermissionCalls, 1);
      expect(usageRepo.getDailyCalls, 0);
      expect(controller.lastUsageFailure, isNull);
      expect(
        controller.lastUsagePermissionStatus,
        UsagePermissionStatus.granted,
      );
      final evaluation = result.valueOrNull!;
      expect(evaluation.dailyQuota.usedMinutes, isNull);
      expect(evaluation.dailyQuota.isUnavailable, isTrue);
      expect(evaluation.dailyQuota.isReached, isFalse);
      expect(
        evaluation.appEvaluations['com.blocked']?.status,
        AppPolicyStatus.blockedByParent,
      );
      expect(evaluation.overallState, PolicyOverallState.scheduleRestricted);
    },
  );
}

final class _FakePolicyRepository implements ChildPolicyRepository {
  Result<ChildPolicyRecord>? result;
  @override
  Future<Result<ChildPolicyRecord>> getPolicy() async =>
      result ?? Ok(ChildPolicyRecord.inMemoryNeutral());
  @override
  Future<Result<void>> saveSyncedPolicy({
    required PolicyConfig config,
    required int policyVersion,
    required DateTime updatedAt,
  }) async => okVoid();
}
