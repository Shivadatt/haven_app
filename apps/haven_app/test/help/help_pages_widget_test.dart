import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/help/controllers/faq_controller.dart';
import 'package:haven_app/features/help/controllers/help_controller.dart';
import 'package:haven_app/features/help/controllers/support_controller.dart';
import 'package:haven_app/features/help/data/local_support_repository.dart';
import 'package:haven_app/features/help/views/pages/contact_support_page.dart';
import 'package:haven_app/features/help/views/pages/faq_page.dart';
import 'package:haven_app/features/help/views/pages/help_center_page.dart';

void main() {
  tearDown(Get.reset);

  group('HelpCenterPage Widget Tests', () {
    testWidgets('renders search, category filters, and article cards', (tester) async {
      final repo = LocalSupportRepository();
      final controller = HelpController(repository: repo);
      Get.put<HelpController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: const HelpCenterPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help Centre'), findsOneWidget);
      expect(find.text('FAQs'), findsOneWidget);
      expect(find.text('Contact Support'), findsOneWidget);
      expect(find.text('Quick Start: Setting Up Haven'), findsOneWidget);
    });
  });

  group('FaqPage Widget Tests', () {
    testWidgets('renders FAQ search, filters and question tiles', (tester) async {
      final repo = LocalSupportRepository();
      final controller = FaqController(repository: repo);
      Get.put<FaqController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: const FaqPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.text('Does Haven hide itself on my child\'s phone?'), findsOneWidget);
    });
  });

  group('ContactSupportPage Widget Tests', () {
    testWidgets('renders offline banner and support ticket form', (tester) async {
      final tables = LocalTables(InMemoryLocalStore());
      await tables.open();
      final repo = LocalSupportRepository(tables: tables);
      final controller = SupportController(repository: repo);
      Get.put<SupportController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: const ContactSupportPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Contact Support'), findsOneWidget);
      expect(find.text('Offline Support Seam'), findsOneWidget);
      expect(find.text('Submit Ticket'), findsOneWidget);
      expect(find.text('Save Draft'), findsOneWidget);
    });
  });
}
