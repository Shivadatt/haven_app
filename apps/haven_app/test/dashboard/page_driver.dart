import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/family/data/family_models.dart';
import 'package:haven_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:haven_app/features/dashboard/data/dashboard_repository.dart';
import 'package:haven_app/features/dashboard/views/pages/dashboard_page.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../family/fakes.dart';
import 'fakes.dart';

/// A `safety_alerts` row, as the backend would return it.
SafetyAlert alert(
  String id, {
  String severity = 'warning',
  String message = 'Left Home',
}) => SafetyAlert(
  id: id,
  familyId: 'f1',
  deviceId: 'd1',
  type: 'geofence_exit',
  severity: severity,
  message: message,
  payload: const <String, Object?>{},
  createdAt: DateTime.utc(2026, 11, 1, 9),
);

/// How a dashboard page test gets onto the page and moves around it.
///
/// [routes] records which verb each navigation used, because "opens on top" and
/// "replaces the stack" are different promises to a parent.
final class DashboardDriver {
  final List<(String, String, Object?)> routes = <(String, String, Object?)>[];
  late FakeDashboardRepository repository;

  Future<void> open(
    WidgetTester tester, {
    DashboardData? data,
    FakeDashboardRepository? repo,
  }) async {
    routes.clear();
    repository = repo ?? FakeDashboardRepository(data: data);
    Get.put<DashboardController>(
      DashboardController(
        repository: repository,
        push: (String route, Object? arg) => routes.add(('push', route, arg)),
        replace: (String route, Object? arg) =>
            routes.add(('replace', route, arg)),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(theme: HavenTheme.light, home: const DashboardPage()),
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

  /// One child called Ivy unless the test says otherwise, so the default page
  /// has something to list.
  DashboardData sampleData({
    List<SafetyAlert> alerts = const [],
    HavenFailure? alertsFailure,
    FamilyBundle? family,
  }) => DashboardData(
    family: family ?? bundle(children: [child('c1', 'Ivy')]),
    alerts: alerts,
    alertsFailure: alertsFailure,
  );
}
