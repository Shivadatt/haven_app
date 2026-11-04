import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/location/controllers/location_controller.dart';
import 'package:haven_app/features/location/views/pages/location_page.dart';

import 'fakes.dart';

/// How a location test gets onto the page. [routes] records the verb each
/// navigation used, because replacing the stack with setup and pushing on top of
/// the dashboard are different promises.
final class LocationDriver {
  final List<(String, String, Object?)> routes = <(String, String, Object?)>[];
  late FakeLocationRepository repository;

  Future<void> open(
    WidgetTester tester, {
    FakeLocationRepository? repo,
    String deviceId = '',
  }) async {
    routes.clear();
    repository = repo ?? FakeLocationRepository();
    Get.put<LocationController>(
      LocationController(
        repository: repository,
        deviceId: deviceId,
        replace: (String route, Object? arg) =>
            routes.add(('replace', route, arg)),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(theme: HavenTheme.light, home: const LocationPage()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(
    WidgetTester tester,
    String label, {
    Type buttonType = FilledButton,
  }) async {
    final Finder action = find.descendant(
      of: find.byType(buttonType),
      matching: find.text(label),
    );
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
  }

  /// Only the fake's own refusal words are used by these tests, so a screen that
  /// paraphrases the gap instead of rendering it fails.
  static const String readGap = 'no place read seeded';

  static const String showCoords = 'Show the exact coordinates';
  static const String hideCoords = 'Hide the exact coordinates';
}
