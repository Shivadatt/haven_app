import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/core/storage/preferences_store.dart';
import 'package:haven_app/features/family/data/family_scope.dart';
import 'package:haven_app/features/policies/controllers/policies_controller.dart';
import 'package:haven_app/features/policies/data/local_policies_repository.dart';
import 'package:haven_app/features/policies/data/policy_config.dart';
import 'package:haven_app/features/policies/views/pages/policies_page.dart';

import '../child_devices/fakes.dart';
import '../support/fakes.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  group('Local Policy Persistence and Banner UI', () {
    testWidgets('renders prominent local configuration banner and cards', (tester) async {
      final tables = LocalTables(InMemoryLocalStore());
      await tables.open();
      final feed = LocalChangeFeed();
      final reader = LocalRowReader(tables);
      final writer = LocalRowWriter(tables, feed);

      await tables.insert(TableName.families, {
        'id': 'fam-1',
        'name': 'The Family',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      await tables.insert(TableName.familyMembers, {
        'id': 'mem-1',
        'family_id': 'fam-1',
        'user_id': 'user-parent',
        'role': 'parent',
        'status': 'active',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      final auth = FakeUserAuth(
        const AuthSession(
          userId: 'user-parent',
          email: 'parent@example.com',
          accessToken: 'tok',
          role: 'parent',
        ),
      );

      final scope = FamilyScopeReader(auth: () => auth, rows: () => reader);
      final vault = FakeVault();
      final prefs = VaultPreferences(() => vault);

      final localRepo = LocalPoliciesRepository(
        scope: () => scope,
        rows: () => reader,
        writer: () => writer,
        prefs: () => prefs,
        devices: () => FakeDevicesRepository(),
      );

      final controller = PoliciesController(repository: localRepo);
      Get.put<PoliciesController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(theme: HavenTheme.light, home: const PoliciesPage()),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('LOCAL CONFIGURATION ONLY — Device enforcement is deferred to child native phase'),
        findsOneWidget,
      );
      expect(find.text('Daily Screen Time Budget'), findsOneWidget);
      expect(find.text('Schedules & Focus Windows'), findsOneWidget);
      expect(find.text('App Restrictions & Limits'), findsOneWidget);
      expect(find.text('Website & Content Filters'), findsOneWidget);
    });

    test('saves policy to TableName.devicePolicies with incremented version', () async {
      final tables = LocalTables(InMemoryLocalStore());
      await tables.open();
      final feed = LocalChangeFeed();
      final reader = LocalRowReader(tables);
      final writer = LocalRowWriter(tables, feed);

      await tables.insert(TableName.families, {
        'id': 'fam-1',
        'name': 'The Family',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      await tables.insert(TableName.familyMembers, {
        'id': 'mem-1',
        'family_id': 'fam-1',
        'user_id': 'user-parent',
        'role': 'parent',
        'status': 'active',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      await tables.insert(TableName.devices, {
        'id': 'dev-child-1',
        'family_id': 'fam-1',
        'display_name': 'Child Android',
        'device_type': 'android',
        'status': 'paired',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      final auth = FakeUserAuth(
        const AuthSession(
          userId: 'user-parent',
          email: 'parent@example.com',
          accessToken: 'tok',
          role: 'parent',
        ),
      );

      final scope = FamilyScopeReader(auth: () => auth, rows: () => reader);
      final vault = FakeVault();
      final prefs = VaultPreferences(() => vault);

      final localRepo = LocalPoliciesRepository(
        scope: () => scope,
        rows: () => reader,
        writer: () => writer,
        prefs: () => prefs,
        devices: () => FakeDevicesRepository(),
      );

      final config = PolicyConfig.defaults().copyWith(dailyScreenTimeMinutes: 90);
      final res = await localRepo.saveConfig(config);
      expect(res.isOk, isTrue);

      final rows = (await reader.rows(TableName.devicePolicies)).valueOrNull!;
      expect(rows, hasLength(1));
      expect(rows.first['version'], 1);
      expect(rows.first['family_id'], 'fam-1');
      expect(rows.first['device_id'], 'dev-child-1');

      // Verify cached in PreferencesStore
      final cached = await prefs.read(PreferenceKey.policyConfig);
      expect(cached, isNotNull);
      expect(cached, contains('"daily_screen_time_limit_minutes":90'));
    });
  });
}
