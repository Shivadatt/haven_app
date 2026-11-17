import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_child/app/routes/child_routes.dart';
import 'package:haven_child/core/native/usage_envelope_models.dart';
import 'package:haven_child/core/permissions/permission_status_source.dart';
import 'package:haven_child/features/child_usage/controllers/child_usage_controller.dart';
import 'package:haven_child/features/child_usage/data/child_usage_repository.dart';
import 'package:haven_child/features/child_usage/views/child_usage_page.dart';
import 'package:haven_child/features/child_usage/views/widgets/daily_screen_time_card.dart';
import 'package:haven_child/features/child_usage/views/widgets/usage_permission_denied_card.dart';
import 'package:haven_child/features/permissions/views/pages/permissions_page.dart';
import 'package:haven_core/haven_core.dart';

import '../../support/fakes.dart';
import '../../support/host.dart';
import 'fake_child_usage_repository.dart';

void main() {
  late FakeChildUsageRepository fakeUsageRepo;

  setUp(() {
    Get.reset();
    fakeUsageRepo = FakeChildUsageRepository(
      permissionResult: const Ok(
        UsagePermissionResult(status: UsagePermissionStatus.granted, apiLevel: 34),
      ),
      dailyUsageResult: const Ok(
        UsageDailyResult(
          apiLevel: 34,
          startTimeMillis: 1000,
          endTimeMillis: 2000,
          totalForegroundMillis: 7200000, // 2h 0m
          dataFreshness: UsageDataFreshness.recent,
          apps: [
            UsageAppRecord(
              packageName: 'com.example.math',
              totalForegroundMillis: 3600000, // 1h 0m
              isSystemApp: false,
            ),
          ],
        ),
      ),
    );
  });

  tearDown(() => Get.reset());

  Future<void> openPermissionsHost(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put<PermissionStatusSource>(FakePermissionStatusSource());
    Get.put<ChildUsageRepository>(fakeUsageRepo);

    await tester.pumpWidget(childAppHost(initialRoute: ChildRoutes.permissions));
    await tester.pumpAndSettle();
  }

  group('Dashboard Navigation Integration', () {
    testWidgets('tapping usageAccess card navigates to /usage and renders ChildUsagePage', (tester) async {
      await openPermissionsHost(tester);

      expect(find.byType(PermissionsPage), findsOneWidget);
      final usageCard = find.byKey(const ValueKey('usage_access'));
      expect(usageCard, findsOneWidget);
      expect(find.text('Screen time access'), findsOneWidget);

      await tester.tap(usageCard);
      await tester.pumpAndSettle();

      expect(Get.currentRoute, equals(ChildRoutes.childUsage));
      expect(find.byType(ChildUsagePage), findsOneWidget);
      expect(find.byType(DailyScreenTimeCard), findsOneWidget);
      expect(find.text('2h 0m'), findsOneWidget);
      expect(find.text('1h 0m'), findsOneWidget);
      expect(find.text('com.example.math'), findsOneWidget);
    });

    testWidgets('back navigation returns to PermissionsPage and handles controller lifecycle', (tester) async {
      await openPermissionsHost(tester);

      await tester.tap(find.byKey(const ValueKey('usage_access')));
      await tester.pumpAndSettle();

      expect(find.byType(ChildUsagePage), findsOneWidget);
      expect(Get.isRegistered<ChildUsageController>(), isTrue);

      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(Get.currentRoute, equals(ChildRoutes.permissions));
      expect(find.byType(PermissionsPage), findsOneWidget);
      expect(find.byType(ChildUsagePage), findsNothing);
    });

    testWidgets('re-entering after revocation shows permission required without stale data', (tester) async {
      await openPermissionsHost(tester);

      await tester.tap(find.byKey(const ValueKey('usage_access')));
      await tester.pumpAndSettle();
      expect(find.text('2h 0m'), findsOneWidget);
      expect(find.text('1h 0m'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Revoke permission on repository
      fakeUsageRepo.permissionResult = const Ok(
        UsagePermissionResult(status: UsagePermissionStatus.denied, apiLevel: 34),
      );

      await tester.tap(find.byKey(const ValueKey('usage_access')));
      await tester.pumpAndSettle();

      expect(find.byType(ChildUsagePage), findsOneWidget);
      expect(find.text('2h 0m'), findsNothing);
      expect(find.text('1h 0m'), findsNothing);
      expect(find.byType(UsagePermissionDeniedCard), findsOneWidget);
    });

    testWidgets('other capability cards remain non-navigating and preserve disabled settings action', (tester) async {
      await openPermissionsHost(tester);

      final locationCard = find.byKey(const ValueKey('location'));
      expect(locationCard, findsOneWidget);

      await tester.tap(locationCard);
      await tester.pumpAndSettle();

      // Should still be on PermissionsPage
      expect(Get.currentRoute, equals(ChildRoutes.permissions));
      expect(find.byType(PermissionsPage), findsOneWidget);
      expect(find.byType(ChildUsagePage), findsNothing);
    });
  });
}
