import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/core/storage/preferences_store.dart';
import 'package:haven_app/features/device_activity/data/local_activity_repository.dart';
import 'package:haven_app/features/family/data/family_scope.dart';
import 'package:haven_app/features/onboarding/data/local_onboarding_repository.dart';
import 'package:haven_app/features/onboarding/data/onboarding_models.dart';
import 'package:haven_app/features/policies/data/local_policies_repository.dart';
import 'package:haven_app/features/policies/data/policy_config.dart';
import 'package:haven_app/features/settings/data/settings_repository.dart';

import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryLocalStore store;
  late LocalTables tables;
  late FakeVault vault;
  late PreferencesStore prefs;

  setUp(() async {
    Get.reset();
    store = InMemoryLocalStore();
    tables = LocalTables(store);
    await tables.open();
    vault = FakeVault();
    prefs = VaultPreferences(() => vault);
    Get.put<LocalTables>(tables);
    Get.put<PreferencesStore>(prefs);
  });

  tearDown(() {
    Get.reset();
  });

  group('Phase 1 Stabilization: Reset & Preferences cleanup', () {
    test('resetAllData clears all local tables and onboarding preferences', () async {
      await prefs.write(PreferenceKey.onboardingCompleted, 'true');
      await prefs.write(PreferenceKey.onboardingStep, 'device');
      await prefs.write(PreferenceKey.onboardingEthicsAcknowledged, 'true');
      await prefs.write(PreferenceKey.policyConfig, '{"daily_limit_minutes": 120}');
      await prefs.write(PreferenceKey.parentDisplayName, 'Jordan');

      final repo = HavenSettingsRepository(
        prefs: () => prefs,
        push: () => const UnconfiguredPushTransport('offline'),
        messagingConfigured: () => false,
      );

      final resetResult = await repo.resetAllData();
      expect(resetResult.isOk, isTrue);

      expect(await prefs.read(PreferenceKey.onboardingCompleted), 'false');
      expect(await prefs.read(PreferenceKey.onboardingStep), '');
      expect(await prefs.read(PreferenceKey.onboardingEthicsAcknowledged), 'false');
      expect(await prefs.read(PreferenceKey.policyConfig), '');
      expect(await prefs.read(PreferenceKey.parentDisplayName), '');
    });
  });

  group('Phase 1 Stabilization: Child age_bracket field parity', () {
    test('LocalOnboardingRepository writes age_bracket for Profile model parity', () async {
      final userAuth = LocalUserAuth(tables, vault);
      final reg = await userAuth.register(
        email: 'parent@test.com',
        password: 'password123',
        displayName: 'Parent Test',
      );
      expect(reg.isOk, isTrue);

      final onboardingRepo = LocalOnboardingRepository(
        auth: () => userAuth,
        rows: () => LocalRowReader(tables),
        writer: () => LocalRowWriter(tables, LocalChangeFeed()),
        profiles: () => LocalProfileStore(tables),
      );

      await onboardingRepo.createFamily(name: 'Test Family');
      final childRes = await onboardingRepo.createChild(
        name: 'Tommy',
        ageGroup: ChildAgeGroup.child.key,
        avatar: 'fox',
      );
      expect(childRes.isOk, isTrue);

      final profileRow = await tables.first(
        TableName.profiles,
        eq: {'id': childRes.valueOrNull!},
      );
      expect(profileRow.isOk, isTrue);
      final data = profileRow.valueOrNull!;
      expect(data['age_bracket'], 'child');
      expect(data['display_name'], 'Tommy');
      expect(data['avatar'], 'fox');
    });
  });

  group('Phase 1 Stabilization: Rapid activity logging uniqueness', () {
    test('consecutive activity events have unique non-colliding IDs', () async {
      final activityRepo = LocalActivityRepository(
        scope: () => FamilyScopeReader(
          auth: () => LocalUserAuth(tables, vault),
          rows: () => LocalRowReader(tables),
        ),
        rows: () => LocalRowReader(tables),
        writer: () => LocalRowWriter(tables, LocalChangeFeed()),
        devices: () => throw UnimplementedError(),
      );

      await tables.insert(TableName.families, {'id': 'fam_x', 'name': 'Family X'});
      await tables.insert(TableName.devices, {
        'id': 'dev_x',
        'family_id': 'fam_x',
        'display_name': 'Phone',
        'platform': 'android',
      });

      // Rapidly log 5 events in immediate sequence
      for (var i = 0; i < 5; i++) {
        final res = await activityRepo.logActivityEvent(
          familyId: 'fam_x',
          deviceId: 'dev_x',
          category: 'app_usage',
          title: 'Event $i',
          subtitle: 'Used app $i',
        );
        expect(res.isOk, isTrue);
      }

      final count = await tables.count(TableName.safetyAlerts);
      expect(count.valueOrNull, 5);
    });
  });

  group('Phase 1 Stabilization: Policies repository device creation schema', () {
    test('fallback device contains platform: android and valid fields', () async {
      final userAuth = LocalUserAuth(tables, vault);
      final reg = await userAuth.register(
        email: 'parent2@test.com',
        password: 'password123',
        displayName: 'Parent 2',
      );
      expect(reg.isOk, isTrue);

      await tables.insert(TableName.families, {'id': 'fam_p', 'name': 'Policy Family'});
      await tables.insert(TableName.familyMembers, {
        'id': 'fm_p',
        'family_id': 'fam_p',
        'user_id': reg.valueOrNull!.userId,
        'role': 'parent',
      });

      final policiesRepo = LocalPoliciesRepository(
        scope: () => FamilyScopeReader(
          auth: () => userAuth,
          rows: () => LocalRowReader(tables),
        ),
        rows: () => LocalRowReader(tables),
        writer: () => LocalRowWriter(tables, LocalChangeFeed()),
        prefs: () => prefs,
        devices: () => throw UnimplementedError(),
      );

      final saveRes = await policiesRepo.saveConfig(PolicyConfig.defaults());
      expect(saveRes.isOk, isTrue);

      final devRows = await tables.rows(TableName.devices, eq: {'family_id': 'fam_p'});
      expect(devRows.valueOrNull!.length, 1);
      final dev = devRows.valueOrNull!.first;
      expect(dev['platform'], 'android');
      expect(dev['status'], 'active');
      expect(dev['enforcement_mode'], 'block');
      expect(dev['policy_version'], 1);
    });
  });
}
