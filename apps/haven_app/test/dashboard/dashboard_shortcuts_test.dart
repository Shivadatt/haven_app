import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:haven_app/features/dashboard/data/dashboard_repository.dart';
import 'package:haven_app/features/dashboard/views/widgets/dashboard_quick_actions_card.dart';
import 'package:haven_core/haven_core.dart';

final class _DummyDashboardRepo implements DashboardRepository {
  @override
  Future<Result<DashboardData>> load() async =>
      const Ok(DashboardData(family: null, alerts: []));

  @override
  Future<Result<List<dynamic>>> pairedDevices() async => const Ok([]);
}

void main() {
  late List<String> navigatedRoutes;
  late DashboardController controller;

  setUp(() {
    Get.reset();
    navigatedRoutes = [];
    controller = DashboardController(
      repository: _DummyDashboardRepo(),
      push: (route, arg) => navigatedRoutes.add(route),
      replace: (route, arg) => navigatedRoutes.add('replace:$route'),
    );
  });

  tearDown(Get.reset);

  test('controller navigates to all Phase 2 quick action targets', () {
    controller.goToAppLimits();
    expect(navigatedRoutes.last, AppRoutes.appLimits);

    controller.goToAppRules();
    expect(navigatedRoutes.last, AppRoutes.appRules);

    controller.goToWebFilter();
    expect(navigatedRoutes.last, AppRoutes.webFilter);

    controller.goToSchedules();
    expect(navigatedRoutes.last, AppRoutes.schedulesEditor);

    controller.goToLocation();
    expect(navigatedRoutes.last, AppRoutes.location);

    controller.goToApprovals();
    expect(navigatedRoutes.last, AppRoutes.appApprovals);

    controller.goToExtensionRequests();
    expect(navigatedRoutes.last, AppRoutes.extensionRequests);

    controller.goToFamily();
    expect(navigatedRoutes.last, AppRoutes.family);

    controller.goToHelp();
    expect(navigatedRoutes.last, AppRoutes.helpCenter);
  });

  testWidgets('renders all quick action shortcuts in the widget', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardQuickActionsCard(controller: controller),
          ),
        ),
      ),
    );

    expect(find.text('Quick Controls'), findsOneWidget);
    expect(find.text('App Limits'), findsOneWidget);
    expect(find.text('App Rules'), findsOneWidget);
    expect(find.text('Web Filter'), findsOneWidget);
    expect(find.text('Schedules'), findsOneWidget);
    expect(find.text('Location Map'), findsOneWidget);
    expect(find.text('Approvals'), findsOneWidget);
    expect(find.text('Extensions'), findsOneWidget);
    expect(find.text('Profiles'), findsOneWidget);
    expect(find.text('Help Centre'), findsOneWidget);

    // Tap App Limits and verify navigation fired
    await tester.tap(find.text('App Limits'));
    await tester.pump();
    expect(navigatedRoutes, contains(AppRoutes.appLimits));
  });
}
