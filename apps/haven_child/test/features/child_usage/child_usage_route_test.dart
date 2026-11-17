import 'package:flutter_test/flutter_test.dart';
import 'package:haven_child/app/routes/app_pages.dart';
import 'package:haven_child/app/routes/app_routes.dart';
import 'package:haven_child/app/routes/child_pages.dart';
import 'package:haven_child/app/routes/child_routes.dart';
import 'package:haven_child/features/child_usage/bindings/child_usage_bindings.dart';
import 'package:haven_child/features/child_usage/views/child_usage_page.dart';

void main() {
  group('Child Usage Route Registration Tests', () {
    test('AppRoutes.childUsage equals /usage and matches ChildRoutes aliases', () {
      expect(AppRoutes.childUsage, equals('/usage'));
      expect(ChildRoutes.childUsage, equals('/usage'));
      expect(ChildRoutes.usage, equals('/usage'));
    });

    test('ChildPages.pages registers /usage exactly once', () {
      final matchingPages = ChildPages.pages.where((p) => p.name == ChildRoutes.childUsage).toList();
      expect(matchingPages.length, equals(1));
    });

    test('AppPages.pages contains all required routes including childUsage', () {
      final routeNames = AppPages.pages.map((p) => p.name).toSet();
      expect(routeNames, contains(ChildRoutes.splash));
      expect(routeNames, contains(ChildRoutes.onboarding));
      expect(routeNames, contains(ChildRoutes.profile));
      expect(routeNames, contains(ChildRoutes.device));
      expect(routeNames, contains(ChildRoutes.permissions));
      expect(routeNames, contains(ChildRoutes.childUsage));
    });

    test('registered page resolves to ChildUsagePage and attaches ChildUsageBindings', () {
      final page = ChildPages.pages.firstWhere((p) => p.name == ChildRoutes.childUsage);
      final widget = page.page();
      expect(widget, isA<ChildUsagePage>());
      expect(page.binding, isA<ChildUsageBindings>());
    });
  });
}
