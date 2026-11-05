import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/settings/controllers/settings_controller.dart';
import 'package:haven_app/features/settings/data/settings_models.dart';
import 'package:haven_app/features/settings/views/widgets/reset_confirm_dialogs.dart';

import 'fakes.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  group('Parent Profile, Local Sign-Out, Demo Reset & Full Reset', () {
    test('parent profile updates name and reflects in state', () async {
      final repo = FakeSettingsRepository(
        profile: const ParentProfileSummary(
          id: 'u-1',
          email: 'parent@example.com',
          displayName: 'Ada',
          role: 'parent',
        ),
      );
      final controller = SettingsController(repository: repo);
      await controller.load();

      expect(controller.parentProfile.value?.displayName, 'Ada');

      final success = await controller.updateParentName('Ada Lovelace');
      expect(success, isTrue);
      expect(controller.parentProfile.value?.displayName, 'Ada Lovelace');
      expect(repo.calls, contains('updateParentName'));
    });

    test('local sign-out clears session and triggers route transition', () async {
      String? routedTo;
      final repo = FakeSettingsRepository();
      final controller = SettingsController(
        repository: repo,
        navigate: (route) => routedTo = route,
      );

      await controller.signOut();
      expect(repo.signedOut, isTrue);
      expect(routedTo, '/sign-in');
    });

    test('demo data reset removes only demo records leaving user rows intact', () async {
      final memoryStore = InMemoryLocalStore();
      final tables = LocalTables(memoryStore);
      await tables.open();
      Get.put<LocalTables>(tables);

      // Seed a user record and a demo record
      await tables.insert(TableName.families, {
        'id': 'fam-user',
        'name': 'Real Family',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'is_demo': false,
      });
      await tables.insert(TableName.families, {
        'id': 'fam-demo',
        'name': 'Demo Family',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'is_demo': true,
      });

      final rowsBefore = (await tables.rows(TableName.families)).valueOrNull!;
      expect(rowsBefore.length, 2);

      final repo = FakeSettingsRepository();
      final controller = SettingsController(repository: repo);
      await controller.resetDemoData();

      expect(repo.demoReset, isTrue);

      // Verify clearDemoData execution on LocalTables
      await tables.clearDemoData();
      final rowsAfter = (await tables.rows(TableName.families)).valueOrNull!;
      expect(rowsAfter.length, 1);
      expect(rowsAfter.first['id'], 'fam-user');
    });

    testWidgets('full data reset requires two-step modal confirmation', (tester) async {
      bool? result;
      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await ResetConfirmDialogs.confirmFullReset(ctx);
              },
              child: const Text('Open Reset'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Reset'));
      await tester.pumpAndSettle();

      // Step 1: Dialog is shown explaining data loss
      expect(find.text('Reset All Local Data?'), findsOneWidget);
      expect(find.textContaining('permanently erase all local tables'), findsOneWidget);

      // Tap continue to reach Step 2
      await tester.tap(find.text('Continue to Final Step'));
      await tester.pumpAndSettle();

      // Step 2: Final confirmation dialog is shown
      expect(find.text('Final Confirmation'), findsOneWidget);
      expect(find.textContaining('Are you absolutely sure'), findsOneWidget);

      // Confirm step 2
      await tester.tap(find.text('Permanently Reset All Data'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('cancelling step 1 aborts full reset flow', (tester) async {
      bool? result;
      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await ResetConfirmDialogs.confirmFullReset(ctx);
              },
              child: const Text('Open Reset'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Reset'));
      await tester.pumpAndSettle();

      expect(find.text('Reset All Local Data?'), findsOneWidget);

      // Cancel at step 1
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Final Confirmation'), findsNothing);
      expect(result, isFalse);
    });
  });
}
