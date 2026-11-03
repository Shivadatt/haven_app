import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/settings/controllers/settings_controller.dart';
import 'package:haven_app/features/settings/data/settings_repository.dart';
import 'package:haven_app/features/settings/views/pages/settings_page.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';

void main() {
  late FakeSettingsRepository repository;
  late List<ThemeMode> applied;

  Future<void> open(
    WidgetTester tester, {
    NotificationAccess access = NotificationAccess.denied,
    ThemeChoice theme = ThemeChoice.system,
  }) async {
    repository = FakeSettingsRepository(access: access, theme: theme);
    applied = <ThemeMode>[];
    Get.put<SettingsController>(
      SettingsController(repository: repository, applyTheme: applied.add),
    );
    await tester.pumpWidget(
      GetMaterialApp(theme: HavenTheme.light, home: const SettingsPage()),
    );
    await tester.pumpAndSettle();
  }

  tearDown(Get.reset);

  testWidgets('the stored choice is the chip that reads as chosen', (
    tester,
  ) async {
    await open(tester, theme: ThemeChoice.dark);

    expect(find.text('Match the phone'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);

    ChoiceChip chipAt(String label) => tester.widget<ChoiceChip>(
      find.ancestor(of: find.text(label), matching: find.byType(ChoiceChip)),
    );
    expect(chipAt('Dark').selected, isTrue);
    expect(chipAt('Light').selected, isFalse);
  });

  testWidgets('picking Dark changes it now and stores it', (tester) async {
    await open(tester);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(applied, [ThemeMode.dark]);
    expect(repository.lastSaved, ThemeChoice.dark);
  });

  testWidgets('an unconfigured build says so instead of blaming the parent', (
    tester,
  ) async {
    await open(tester, access: NotificationAccess.unavailable);

    expect(find.text('Not in this build'), findsOneWidget);
    expect(find.text('Allow notifications'), findsNothing);
  });

  testWidgets('a refused permission offers one way to change it', (
    tester,
  ) async {
    await open(tester);
    repository.prompt = const Ok<bool>(true);

    expect(find.text('Off'), findsOneWidget);
    await tester.ensureVisible(find.text('Allow notifications'));
    await tester.tap(find.text('Allow notifications'));
    await tester.pumpAndSettle();

    expect(find.text('On'), findsOneWidget);
  });

  testWidgets('the rest of the settings screens are reachable', (tester) async {
    await open(tester);

    for (final String label in [
      'Your account',
      'Permissions Haven needs',
      'About Haven',
    ]) {
      expect(find.text(label), findsOneWidget, reason: '$label is missing');
    }
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(3));
  });
}
