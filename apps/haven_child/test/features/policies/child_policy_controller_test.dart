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
  test('initial loading refuses evaluation; neutral load permits it', () async {
    expect(
      (await controller.evaluate()).failureOrNull?.detail,
      'policy_not_ready',
    );
    policyRepo.result = Ok(ChildPolicyRecord.inMemoryNeutral());
    await controller.loadPolicy();
    usageRepo.dailyUsageResult = Ok(usage([app('com.a')]));
    expect((await controller.evaluate()).isOk, isTrue);
    expect(controller.status.value, ChildPolicyStatus.ready);
    expect(
      controller.lastEvaluation.value?.appEvaluations['com.a']?.usedMinutes,
      2,
    );
  });
  test('failed initial load refuses evaluation and records failure', () async {
    policyRepo.result = Err(StorageFailure('bad policy', detail: 'bad'));
    expect((await controller.loadPolicy()).isErr, isTrue);
    expect(controller.status.value, ChildPolicyStatus.failure);
    expect(
      (await controller.evaluate()).failureOrNull?.detail,
      'policy_evaluation_refused',
    );
  });
  test(
    'reload replaces the active policy; failed reload keeps it diagnostic-only',
    () async {
      policyRepo.result = Ok(synced(config(blocked: ['com.a'])));
      await controller.loadPolicy();
      policyRepo.result = Ok(synced(config(blocked: ['com.b'])));
      await controller.loadPolicy();
      usageRepo.dailyUsageResult = Ok(usage([app('com.a')]));
      final evaluation = (await controller.evaluate()).valueOrNull!;
      expect(
        evaluation.appEvaluations['com.a']?.status,
        AppPolicyStatus.allowed,
      );
      expect(
        evaluation.appEvaluations['com.b']?.status,
        AppPolicyStatus.blockedByParent,
      );
      policyRepo.result = Err(StorageFailure('reload failed', detail: 'bad'));
      expect((await controller.loadPolicy()).isErr, isTrue);
      expect(controller.lastValidPolicy, isNotNull);
      expect(
        (await controller.evaluate()).failureOrNull?.detail,
        'policy_evaluation_refused',
      );
    },
  );
  test(
    'disposed controller refuses evaluation and ignores late completion',
    () async {
      policyRepo.result = Ok(ChildPolicyRecord.inMemoryNeutral());
      await controller.loadPolicy();
      usageRepo.dailyUsageDelay = const Duration(milliseconds: 50);
      usageRepo.dailyUsageResult = Ok(usage([app('com.a')]));
      final pending = controller.evaluate();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      controller.onClose();
      final result = await pending;
      expect(result.failureOrNull?.detail, 'policy_controller_disposed');
      expect(controller.lastEvaluation.value, isNull);
    },
  );
  test(
    'permission outcomes skip or query correctly and stay distinct',
    () async {
      policyRepo.result = Ok(ChildPolicyRecord.inMemoryNeutral());
      await controller.loadPolicy();
      final failure = BackendFailure('probe failed', code: 'probe_failed');
      usageRepo.permissionResult = Err(failure);
      expect((await controller.evaluate()).isOk, isTrue);
      expect(usageRepo.getDailyCalls, 0);
      expect(controller.lastUsageFailure, same(failure));
      expect(controller.lastUsagePermissionStatus, isNull);
      for (final status in [
        UsagePermissionStatus.denied,
        UsagePermissionStatus.unsupported,
      ]) {
        usageRepo.permissionResult = Ok(
          UsagePermissionResult(status: status, apiLevel: 34),
        );
        expect((await controller.evaluate()).isOk, isTrue);
        expect(usageRepo.getDailyCalls, 0);
        expect(controller.lastUsageFailure, isNull);
        expect(controller.lastUsagePermissionStatus, status);
      }
    },
  );
  test('stale evaluation after reload cannot publish state', () async {
    policyRepo.result = Ok(ChildPolicyRecord.inMemoryNeutral());
    await controller.loadPolicy();
    usageRepo.dailyUsageDelay = const Duration(milliseconds: 50);
    usageRepo.dailyUsageResult = Ok(usage([app('com.a')]));
    final pending = controller.evaluate();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await controller.loadPolicy();
    final result = await pending;
    expect(result.failureOrNull?.detail, 'policy_evaluation_refused');
    expect(controller.lastEvaluation.value, isNull);
  });
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
