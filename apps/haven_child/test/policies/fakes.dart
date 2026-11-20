import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';
import 'package:haven_child/features/policies/data/child_policy_record.dart';
import 'package:haven_child/features/policies/data/child_policy_repository.dart';

/// In-memory fake repository for unit and widget testing.
final class FakeChildPolicyRepository implements ChildPolicyRepository {
  FakeChildPolicyRepository([ChildPolicyRecord? initial])
    : _current = initial ?? ChildPolicyRecord.inMemoryNeutral();

  ChildPolicyRecord _current;
  int saveCount = 0;

  @override
  Future<Result<ChildPolicyRecord>> getPolicy() async => Ok(_current);

  @override
  Future<Result<void>> saveSyncedPolicy({
    required PolicyConfig config,
    required int policyVersion,
    required DateTime updatedAt,
  }) async {
    saveCount++;
    _current = ChildPolicyRecord.parentSynced(
      config: config,
      policyVersion: policyVersion,
      updatedAt: updatedAt.toUtc(),
    );
    return okVoid();
  }
}

/// Canonical test fixtures for policy tests.
abstract final class PolicyTestFixtures {
  static final DateTime canonicalTimestamp = DateTime.utc(2026, 11, 20, 10, 0);

  static const PolicySchedule bedtimeSchedule = PolicySchedule(
    id: 'sched-bedtime',
    name: 'Bedtime',
    type: PolicyScheduleType.bedtime,
    startTime: '21:00',
    endTime: '07:00',
    days: [1, 2, 3, 4, 5, 6, 7],
    isActive: true,
  );

  static const PolicySchedule schoolSchedule = PolicySchedule(
    id: 'sched-school',
    name: 'School Hours',
    type: PolicyScheduleType.school,
    startTime: '08:30',
    endTime: '15:00',
    days: [1, 2, 3, 4, 5],
    isActive: true,
    allowedApps: ['com.android.calculator2'],
  );

  static const PolicyConfig sampleParentPolicy = PolicyConfig(
    dailyScreenTimeMinutes: 120,
    schedules: [bedtimeSchedule, schoolSchedule],
    allowedApps: ['com.android.calculator2'],
    blockedApps: ['com.zhiliaoapp.musically'],
    appLimits: {'com.google.android.youtube': 30},
    allowedDomains: ['wikipedia.org'],
    blockedDomains: ['tiktok.com'],
    safeSearchEnabled: true,
  );
}
