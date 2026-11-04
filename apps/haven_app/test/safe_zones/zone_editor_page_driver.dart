import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/safe_zones/controllers/zone_editor_controller.dart';
import 'package:haven_app/features/safe_zones/views/pages/safe_zone_editor_page.dart';

import 'fakes.dart';

/// How an editor test opens the form, with the two side effects a controller is
/// allowed to have — closing the screen and replacing the stack — recorded
/// instead of performed.
final class ZoneEditorDriver {
  final List<String> replaces = <String>[];
  int closed = 0;
  late FakeSafeZonesRepository repository;
  late SafeZoneEditorController controller;

  Future<void> open(
    WidgetTester tester, {
    FakeSafeZonesRepository? repo,
    String zoneId = 'z1',
  }) async {
    replaces.clear();
    closed = 0;
    repository = repo ?? FakeSafeZonesRepository(found: zone(zoneId));
    controller = SafeZoneEditorController(
      zoneId: zoneId,
      repository: repository,
      replace: (String route, Object? arg) => replaces.add(route),
      close: () => closed++,
    );
    Get.put<SafeZoneEditorController>(controller);
    await tester.pumpWidget(
      GetMaterialApp(theme: HavenTheme.light, home: const SafeZoneEditorPage()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String label, String value) async {
    await tester.enterText(find.widgetWithText(TextFormField, label), value);
    await tester.pumpAndSettle();
  }

  Future<void> press(
    WidgetTester tester,
    String label, {
    Type buttonType = FilledButton,
  }) async {
    final Finder action = find.widgetWithText(buttonType, label);
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
  }

  /// Whether the primary action can actually be pressed.
  bool saveEnabled(WidgetTester tester) =>
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, saveLabel))
          .onPressed !=
      null;

  static const String saveLabel = 'Save the change';
  static const String removeLabel = 'Remove this place';
  static const String confirmLabel = 'Remove it';
  static const String readGap = 'no place seeded';
}
