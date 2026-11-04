import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/policies/controllers/policies_controller.dart';
import 'package:haven_app/features/policies/views/pages/policies_page.dart';

import 'fakes.dart';

/// How a rules test gets onto the page. [routes] records the verb each navigation
/// used, because replacing the stack with setup and pushing on top of the
/// dashboard are different promises.
final class PoliciesDriver {
  final List<(String, String, Object?)> routes = <(String, String, Object?)>[];
  late FakePoliciesRepository repository;

  Future<void> open(
    WidgetTester tester, {
    FakePoliciesRepository? repo,
    String deviceId = '',
  }) async {
    routes.clear();
    repository = repo ?? FakePoliciesRepository();
    Get.put<PoliciesController>(
      PoliciesController(
        repository: repository,
        deviceId: deviceId,
        replace: (String route, Object? arg) =>
            routes.add(('replace', route, arg)),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(theme: HavenTheme.light, home: const PoliciesPage()),
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

  /// §2 of the brief forbids a control that can only ever be refused, so on a
  /// loaded board this has to be zero: the screen is a read.
  int get actionableButtons => _count() + _count(OutlinedButton);

  int _count([Type kind = FilledButton]) => find
      .byType(kind)
      .evaluate()
      .map((Element e) => e.widget)
      .whereType<ButtonStyleButton>()
      .where((ButtonStyleButton button) => button.onPressed != null)
      .length;

  /// Only the fake's own refusal words are used by these tests, so a screen that
  /// paraphrases the gap instead of rendering it fails.
  static const String readGap = 'no version read seeded';

  static const String setup = 'Start setup';

  static const String emptyLine =
      'No rule version has been written for this family yet.';
}
