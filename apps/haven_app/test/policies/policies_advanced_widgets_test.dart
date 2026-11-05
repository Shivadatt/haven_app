import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/policies/controllers/app_limits_controller.dart';
import 'package:haven_app/features/policies/controllers/app_rules_controller.dart';
import 'package:haven_app/features/policies/controllers/web_filter_controller.dart';
import 'package:haven_app/features/policies/views/pages/app_limits_page.dart';
import 'package:haven_app/features/policies/views/pages/app_rules_page.dart';
import 'package:haven_app/features/policies/views/pages/web_filter_page.dart';

import '../child_devices/fakes.dart';
import 'fakes.dart';

void main() {
  tearDown(Get.reset);

  group('AppLimitsPage Widget Tests', () {
    testWidgets('renders list of catalogue apps with limit details', (tester) async {
      final policiesRepo = FakePoliciesRepository(canConfigure: true);
      final devicesRepo = FakeDevicesRepository(
        devices: [fakeDevice('d1', name: 'Child Tablet')],
      );
      final controller = AppLimitsController(
        policiesRepo: policiesRepo,
        devicesRepo: devicesRepo,
        initialDeviceId: 'd1',
      );
      Get.put<AppLimitsController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: const AppLimitsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('App Limits'), findsOneWidget);
      expect(find.textContaining('LOCAL POLICY CONFIGURATION ONLY'), findsOneWidget);
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('30 minutes daily limit'), findsOneWidget);
    });
  });

  group('AppRulesPage Widget Tests', () {
    testWidgets('renders allowed and blocked segments and toggles tabs', (tester) async {
      final policiesRepo = FakePoliciesRepository(canConfigure: true);
      final devicesRepo = FakeDevicesRepository(
        devices: [fakeDevice('d1', name: 'Child Tablet')],
      );
      final controller = AppRulesController(
        policiesRepo: policiesRepo,
        devicesRepo: devicesRepo,
        initialDeviceId: 'd1',
      );
      Get.put<AppRulesController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: const AppRulesPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('App Rules'), findsOneWidget);
      expect(find.textContaining('LOCAL POLICY CONFIGURATION ONLY'), findsOneWidget);

      final blockedSegment = find.textContaining('Blocked');
      expect(blockedSegment, findsOneWidget);
      await tester.tap(blockedSegment);
      await tester.pumpAndSettle();

      expect(controller.activeTabIndex.value, equals(1));
    });
  });

  group('WebFilterPage Widget Tests', () {
    testWidgets('renders SafeSearch switch and domain filter segments', (tester) async {
      final policiesRepo = FakePoliciesRepository(canConfigure: true);
      final devicesRepo = FakeDevicesRepository(
        devices: [fakeDevice('d1', name: 'Child Tablet')],
      );
      final controller = WebFilterController(
        policiesRepo: policiesRepo,
        devicesRepo: devicesRepo,
        initialDeviceId: 'd1',
      );
      Get.put<WebFilterController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: const WebFilterPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Website Filter'), findsOneWidget);
      expect(find.text('Enforce SafeSearch'), findsOneWidget);
      expect(find.textContaining('LOCAL RULES ONLY'), findsOneWidget);

      final safeSearchTile = find.byType(SwitchListTile);
      expect(safeSearchTile, findsOneWidget);

      await tester.tap(safeSearchTile);
      await tester.pumpAndSettle();

      expect(controller.config.value.safeSearchEnabled, isFalse);
    });
  });
}
