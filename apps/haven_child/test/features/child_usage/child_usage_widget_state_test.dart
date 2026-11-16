import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_child/core/native/usage_envelope_models.dart';
import 'package:haven_child/features/child_usage/controllers/child_usage_controller.dart';
import 'package:haven_child/features/child_usage/views/child_usage_page.dart';
import 'package:haven_child/features/child_usage/views/widgets/daily_screen_time_card.dart';
import 'package:haven_child/features/child_usage/views/widgets/usage_access_explainer_card.dart';
import 'package:haven_child/features/child_usage/views/widgets/usage_permission_denied_card.dart';
import 'package:haven_core/haven_core.dart';

import '../../support/host.dart';
import 'fake_child_usage_repository.dart';

void main() {
  late FakeChildUsageRepository repo;

  setUp(() {
    Get.reset();
    repo = FakeChildUsageRepository();
  });

  tearDown(() => Get.reset());

  Future<void> pumpPage(WidgetTester tester, ChildUsageController controller) async {
    Get.put<ChildUsageController>(controller);
    await tester.pumpWidget(childHost(const ChildUsagePage()));
    await tester.pump();
  }

  testWidgets('renders loading view while operation is in flight', (tester) async {
    repo.permissionDelay = const Duration(milliseconds: 50);
    final controller = ChildUsageController(repository: repo);
    await pumpPage(tester, controller);

    expect(find.text('Loading usage data...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('renders permission required view when access is denied', (tester) async {
    repo.permissionResult = const Ok(
      UsagePermissionResult(status: UsagePermissionStatus.denied, apiLevel: 34),
    );
    final controller = ChildUsageController(repository: repo);
    await pumpPage(tester, controller);
    await tester.pumpAndSettle();

    expect(find.byType(UsagePermissionDeniedCard), findsOneWidget);
    expect(find.byType(UsageAccessExplainerCard), findsOneWidget);
    expect(find.text('Permission Required'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
  });

  testWidgets('renders unsupported view on unsupported platform', (tester) async {
    repo.permissionResult = const Ok(
      UsagePermissionResult(status: UsagePermissionStatus.unsupported, apiLevel: 19),
    );
    final controller = ChildUsageController(repository: repo);
    await pumpPage(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('Platform Not Supported'), findsOneWidget);
    expect(find.byType(UsageAccessExplainerCard), findsOneWidget);
  });

  testWidgets('renders loaded daily usage and app records', (tester) async {
    repo.dailyUsageResult = const Ok(
      UsageDailyResult(
        apiLevel: 34,
        startTimeMillis: 1000,
        endTimeMillis: 2000,
        totalForegroundMillis: 7200000, // 2h 0m
        dataFreshness: UsageDataFreshness.recent,
        apps: [
          UsageAppRecord(
            packageName: 'com.example.learning',
            totalForegroundMillis: 5400000, // 1h 30m
            isSystemApp: false,
          ),
        ],
      ),
    );
    final controller = ChildUsageController(repository: repo);
    await pumpPage(tester, controller);
    await tester.pumpAndSettle();

    expect(find.byType(DailyScreenTimeCard), findsOneWidget);
    expect(find.text('2h 0m'), findsOneWidget);
    expect(find.text('1h 30m'), findsOneWidget);
    expect(find.text('com.example.learning'), findsOneWidget);
    expect(find.byType(UsageAccessExplainerCard), findsOneWidget);
  });

  testWidgets('renders error view on failure and allows retry', (tester) async {
    repo.permissionResult = const Err(BackendFailure('Native bridge failed'));
    final controller = ChildUsageController(repository: repo);
    await pumpPage(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('Unable to Load Usage'), findsOneWidget);
    expect(find.text('Native bridge failed'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);

    repo.permissionResult = const Ok(
      UsagePermissionResult(status: UsagePermissionStatus.granted, apiLevel: 34),
    );
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to Load Usage'), findsNothing);
    expect(find.byType(DailyScreenTimeCard), findsOneWidget);
  });

  testWidgets('settings action launches settings and does not optimistically grant', (tester) async {
    repo.permissionResult = const Ok(
      UsagePermissionResult(status: UsagePermissionStatus.denied, apiLevel: 34),
    );
    final controller = ChildUsageController(repository: repo);
    await pumpPage(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    expect(repo.openSettingsCalls, equals(1));
    expect(controller.isPermissionGranted, isFalse);
    expect(find.byType(UsagePermissionDeniedCard), findsOneWidget);
  });

  testWidgets('revocation privacy: loaded data immediately disappears on revocation', (tester) async {
    repo.dailyUsageResult = const Ok(
      UsageDailyResult(
        apiLevel: 34,
        startTimeMillis: 1000,
        endTimeMillis: 2000,
        totalForegroundMillis: 7200000,
        dataFreshness: UsageDataFreshness.recent,
        apps: [
          UsageAppRecord(
            packageName: 'com.secret.app',
            totalForegroundMillis: 3600000,
            isSystemApp: false,
          ),
        ],
      ),
    );
    final controller = ChildUsageController(repository: repo);
    await pumpPage(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('2h 0m'), findsOneWidget);
    expect(find.text('1h 0m'), findsOneWidget);
    expect(find.text('com.secret.app'), findsOneWidget);

    // Permission revoked!
    repo.permissionResult = const Ok(
      UsagePermissionResult(status: UsagePermissionStatus.denied, apiLevel: 34),
    );
    await controller.loadUsage();
    await tester.pumpAndSettle();

    expect(find.text('2h 0m'), findsNothing);
    expect(find.text('1h 0m'), findsNothing);
    expect(find.text('com.secret.app'), findsNothing);
    expect(find.byType(UsagePermissionDeniedCard), findsOneWidget);
  });
}
