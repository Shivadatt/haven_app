import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/core/storage/preferences_store.dart';
import 'package:haven_app/features/family/data/family_scope.dart';
import 'package:haven_app/features/policies/data/local_policies_repository.dart';
import 'package:haven_models/haven_models.dart';

import '../child_devices/fakes.dart';
import '../support/fakes.dart';

void main() {
  late LocalTables tables;
  late LocalRowReader reader;
  late LocalPoliciesRepository localRepo;

  final noon = DateTime(2026, 11, 18, 12, 0);
  final afternoon = DateTime(2026, 11, 18, 16, 0);
  final night = DateTime(2026, 11, 18, 22, 0);

  PolicyUsageSnapshot makeUsage(DateTime time, {int total = 0, Map<String, int> apps = const {}}) {
    final day = DateTime(time.year, time.month, time.day);
    return PolicyUsageSnapshot(
      snapshotDate: day,
      snapshotTime: time,
      startInterval: day,
      endInterval: DateTime(time.year, time.month, time.day, 23, 59),
      totalForegroundMillis: total * 60 * 1000,
      appForegroundMillis: {for (final e in apps.entries) e.key: e.value * 60 * 1000},
      completeness: PolicyUsageCompleteness.complete,
      freshness: PolicyUsageFreshness.recent,
      isPermissionGranted: true,
    );
  }

  setUp(() async {
    tables = LocalTables(InMemoryLocalStore());
    await tables.open();
    final feed = LocalChangeFeed();
    reader = LocalRowReader(tables);
    final writer = LocalRowWriter(tables, feed);

    final now = DateTime.now().toUtc().toIso8601String();
    await tables.insert(TableName.families, {'id': 'fam-1', 'name': 'Family', 'created_at': now});
    await tables.insert(TableName.familyMembers, {
      'id': 'mem-1', 'family_id': 'fam-1', 'user_id': 'user-parent', 'role': 'parent',
      'status': 'active', 'created_at': now,
    });
    await tables.insert(TableName.devices, {
      'id': 'dev-child-1', 'family_id': 'fam-1', 'display_name': 'Child Android',
      'device_type': 'android', 'status': 'paired', 'created_at': now,
    });

    final auth = FakeUserAuth(const AuthSession(
      userId: 'user-parent', email: 'parent@example.com', accessToken: 'tok', role: 'parent',
    ));
    final scope = FamilyScopeReader(auth: () => auth, rows: () => reader);
    final prefs = VaultPreferences(() => FakeVault());

    localRepo = LocalPoliciesRepository(
      scope: () => scope, rows: () => reader, writer: () => writer,
      prefs: () => prefs, devices: () => FakeDevicesRepository(),
    );
  });

  group('Parent Policy Configuration -> Persistence -> Evaluator Synchronization', () {
    test('persists configured policy and verifies evaluator enforcement cascade', () async {
      final config = PolicyConfig(
        dailyScreenTimeMinutes: 90,
        schedules: [PolicySchedule.defaultBedtime()],
        allowedApps: const ['com.android.calculator2'],
        blockedApps: const ['com.zhiliaoapp.musically'],
        appLimits: const {'com.google.android.youtube': 30},
        allowedDomains: const ['wikipedia.org'],
        blockedDomains: const ['tiktok.com'],
        safeSearchEnabled: true,
      );

      final saveResult = await localRepo.saveConfig(config, deviceId: 'dev-child-1');
      expect(saveResult.isOk, isTrue);

      final rows = (await reader.rows(TableName.devicePolicies)).valueOrNull!;
      expect(rows, hasLength(1));
      expect(rows.first['device_id'], 'dev-child-1');
      expect(rows.first['version'], 1);

      final syncedConfig = PolicyConfig.fromJson(asMap(rows.first['policy']));
      expect(syncedConfig.dailyScreenTimeMinutes, 90);
      expect(syncedConfig.allowedApps, contains('com.android.calculator2'));
      expect(syncedConfig.blockedApps, contains('com.zhiliaoapp.musically'));
      expect(syncedConfig.appLimits['com.google.android.youtube'], 30);
      expect(syncedConfig.allowedDomains, contains('wikipedia.org'));
      expect(syncedConfig.blockedDomains, contains('tiktok.com'));

      final daytimeUsage = makeUsage(noon, total: 45, apps: {
        'com.google.android.youtube': 35,
        'com.android.calculator2': 10,
      });
      final daytimeResult = PolicyEvaluator.evaluate(
        context: PolicyEvaluationContext(config: syncedConfig, evaluationTime: noon),
        usage: daytimeUsage,
        targetPackages: const [
          'com.zhiliaoapp.musically',
          'com.google.android.youtube',
          'com.android.calculator2',
          'com.google.android.dialer',
        ],
      );

      expect(daytimeResult.appEvaluations['com.zhiliaoapp.musically']?.status, AppPolicyStatus.blockedByParent);
      expect(daytimeResult.appEvaluations['com.google.android.youtube']?.status, AppPolicyStatus.appLimitReached);
      expect(daytimeResult.appEvaluations['com.android.calculator2']?.status, AppPolicyStatus.allowed);
      expect(daytimeResult.appEvaluations['com.google.android.dialer']?.status, AppPolicyStatus.exempt);
    });

    test('evaluates bedtime restrictions and emergency exemptions from synced policy', () async {
      final config = PolicyConfig(
        dailyScreenTimeMinutes: 90,
        schedules: [PolicySchedule.defaultBedtime()],
        allowedApps: const ['com.android.calculator2'],
        blockedApps: const ['com.zhiliaoapp.musically'],
        appLimits: const {},
        allowedDomains: const [],
        blockedDomains: const [],
      );
      await localRepo.saveConfig(config, deviceId: 'dev-child-1');

      final rows = (await reader.rows(TableName.devicePolicies)).valueOrNull!;
      final syncedConfig = PolicyConfig.fromJson(asMap(rows.first['policy']));

      final bedtimeResult = PolicyEvaluator.evaluate(
        context: PolicyEvaluationContext(config: syncedConfig, evaluationTime: night),
        usage: makeUsage(night, total: 10),
        targetPackages: const [
          'com.android.calculator2',
          'com.google.android.dialer',
          'com.zhiliaoapp.musically',
        ],
      );

      expect(bedtimeResult.overallState, PolicyOverallState.bedtimeActive);
      expect(bedtimeResult.isDowntimeActive, isTrue);
      expect(bedtimeResult.appEvaluations['com.android.calculator2']?.status, AppPolicyStatus.scheduleRestricted);
      expect(bedtimeResult.appEvaluations['com.google.android.dialer']?.status, AppPolicyStatus.exempt);
      expect(bedtimeResult.appEvaluations['com.zhiliaoapp.musically']?.status, AppPolicyStatus.blockedByParent);
    });

    test('evaluates daily quota exhaustion from synced policy', () async {
      final config = PolicyConfig(
        dailyScreenTimeMinutes: 60,
        schedules: [PolicySchedule.defaultBedtime()],
        allowedApps: const ['com.android.calculator2'],
        blockedApps: const [],
        appLimits: const {},
        allowedDomains: const [],
        blockedDomains: const [],
      );
      await localRepo.saveConfig(config, deviceId: 'dev-child-1');

      final rows = (await reader.rows(TableName.devicePolicies)).valueOrNull!;
      final syncedConfig = PolicyConfig.fromJson(asMap(rows.first['policy']));

      final quotaResult = PolicyEvaluator.evaluate(
        context: PolicyEvaluationContext(config: syncedConfig, evaluationTime: afternoon),
        usage: makeUsage(afternoon, total: 65, apps: {'com.example.game': 15}),
        targetPackages: const [
          'com.example.game',
          'com.android.calculator2',
          'com.google.android.dialer',
        ],
      );

      expect(quotaResult.dailyQuota.isReached, isTrue);
      expect(quotaResult.appEvaluations['com.example.game']?.status, AppPolicyStatus.dailyLimitReached);
      expect(quotaResult.appEvaluations['com.android.calculator2']?.status, AppPolicyStatus.allowed);
      expect(quotaResult.appEvaluations['com.google.android.dialer']?.status, AppPolicyStatus.exempt);
    });
  });
}
