import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/safe_zones/controllers/zones_controller.dart';
import 'package:haven_app/features/safe_zones/views/pages/safe_zones_page.dart';

import 'fakes.dart';

/// How a safe-place test gets onto the list. [routes] records the verb each
/// navigation used: pushing onto the dashboard and replacing the stack with setup
/// are different promises, and the page must keep them apart.
final class SafeZonesDriver {
  final List<(String, String, Object?)> routes = <(String, String, Object?)>[];
  late FakeSafeZonesRepository repository;

  Future<void> open(
    WidgetTester tester, {
    FakeSafeZonesRepository? repo,
  }) async {
    routes.clear();
    repository = repo ?? FakeSafeZonesRepository();
    Get.put<SafeZonesController>(
      SafeZonesController(
        repository: repository,
        push: (String route, Object? arg) => routes.add(('push', route, arg)),
        replace: (String route, Object? arg) =>
            routes.add(('replace', route, arg)),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(theme: HavenTheme.light, home: const SafeZonesPage()),
    );
    await tester.pumpAndSettle();
  }

  /// `[which]` is which match to press, because a list of places repeats its
  /// controls and a finder with two matches cannot be tapped.
  Future<void> press(
    WidgetTester tester,
    String label, {
    Type buttonType = FilledButton,
    int which = 0,
  }) async {
    final Finder action = find
        .descendant(of: find.byType(buttonType), matching: find.text(label))
        .at(which);
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
  }

  static const String readGap = 'no place read seeded';
  static const String edit = 'Edit this place';
  static const String emptyLine =
      'No place is named for this family yet. A device cannot be told when it '
      'has arrived somewhere Haven does not know about.';
}
