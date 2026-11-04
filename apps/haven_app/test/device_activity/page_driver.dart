import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/device_activity/controllers/activity_controller.dart';
import 'package:haven_app/features/device_activity/views/pages/activity_page.dart';

import 'fakes.dart';

/// How an activity test gets onto the page. [routes] records the verb each
/// navigation used, because replacing the stack with setup and pushing on top of
/// an empty dashboard are different promises.
final class ActivityDriver {
  final List<(String, String, Object?)> routes = <(String, String, Object?)>[];
  late FakeActivityRepository repository;

  Future<void> open(WidgetTester tester, {FakeActivityRepository? repo}) async {
    routes.clear();
    repository = repo ?? FakeActivityRepository();
    Get.put<ActivityController>(
      ActivityController(
        repository: repository,
        replace: (String route, Object? arg) =>
            routes.add(('replace', route, arg)),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(theme: HavenTheme.light, home: const ActivityPage()),
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
  static const String readGap = 'no usage read seeded';

  List<String> get moved => routes.map((r) => r.$2).toList(growable: false);
}
