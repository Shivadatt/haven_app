import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/approvals/controllers/app_approvals_controller.dart';
import 'package:haven_app/features/approvals/controllers/extension_requests_controller.dart';
import 'package:haven_app/features/approvals/data/local_approvals_repository.dart';
import 'package:haven_app/features/approvals/views/pages/app_approvals_page.dart';
import 'package:haven_app/features/approvals/views/pages/extension_requests_page.dart';

void main() {
  tearDown(Get.reset);

  group('AppApprovalsPage Widget Tests', () {
    testWidgets('renders tabs and sample requests, handles tab switching', (tester) async {
      final tables = LocalTables(InMemoryLocalStore());
      await tables.open();
      final repo = LocalApprovalsRepository(tables: tables);
      final controller = AppApprovalsController(repository: repo);
      Get.put<AppApprovalsController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: const AppApprovalsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('App Install Requests'), findsOneWidget);
      expect(find.text('Pending (1)'), findsOneWidget);
      expect(find.text('Approved (1)'), findsOneWidget);
      expect(find.text('Rejected (1)'), findsOneWidget);

      expect(find.text('Roblox'), findsOneWidget);

      await tester.tap(find.text('Approved (1)'));
      await tester.pumpAndSettle();

      expect(controller.currentTab.value, equals(1));
      expect(find.text('Duolingo'), findsOneWidget);
    });
  });

  group('ExtensionRequestsPage Widget Tests', () {
    testWidgets('renders extension requests and history tab', (tester) async {
      final tables = LocalTables(InMemoryLocalStore());
      await tables.open();
      final repo = LocalApprovalsRepository(tables: tables);
      final controller = ExtensionRequestsController(repository: repo);
      Get.put<ExtensionRequestsController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: const ExtensionRequestsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Screen-Time Requests'), findsOneWidget);
      expect(find.text('Pending (1)'), findsOneWidget);
      expect(find.text('History (1)'), findsOneWidget);

      expect(find.text('Emma • +30 min request'), findsOneWidget);

      await tester.tap(find.text('History (1)'));
      await tester.pumpAndSettle();

      expect(controller.currentTab.value, equals(1));
      expect(find.text('Lucas • +15 min request'), findsOneWidget);
    });
  });
}
