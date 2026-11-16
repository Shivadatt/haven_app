import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_child/core/native/usage_envelope_models.dart';
import 'package:haven_child/features/child_usage/controllers/child_usage_controller.dart';
import 'package:haven_child/features/child_usage/views/child_usage_page.dart';
import 'package:haven_core/haven_core.dart';

import '../../support/host.dart';
import 'fake_child_usage_repository.dart';

void main() {
  late FakeChildUsageRepository repo;

  setUp(() {
    Get.reset();
    repo = FakeChildUsageRepository(
      dailyUsageResult: const Ok(
        UsageDailyResult(
          apiLevel: 34,
          startTimeMillis: 1000,
          endTimeMillis: 2000,
          totalForegroundMillis: 9000000, // 2h 30m
          dataFreshness: UsageDataFreshness.recent,
          apps: [
            UsageAppRecord(
              packageName: 'com.very.long.package.name.identifier.for.testing.overflow',
              totalForegroundMillis: 5400000,
              isSystemApp: true,
            ),
            UsageAppRecord(
              packageName: 'com.standard.app',
              totalForegroundMillis: 3600000,
              isSystemApp: false,
            ),
          ],
        ),
      ),
    );
  });

  tearDown(() => Get.reset());

  Future<void> pumpAtSize(WidgetTester tester, double width, {Brightness brightness = Brightness.light}) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put<ChildUsageController>(ChildUsageController(repository: repo));
    await tester.pumpWidget(childHost(const ChildUsagePage(), brightness: brightness));
    await tester.pumpAndSettle();
  }

  group('Responsive Layout Widths', () {
    for (final width in [320.0, 360.0, 393.0, 412.0, 800.0]) {
      testWidgets('renders cleanly with no overflow at ${width}px', (tester) async {
        await pumpAtSize(tester, width);

        expect(find.byType(ChildUsagePage), findsOneWidget);
        expect(find.text("Today's Screen Time"), findsOneWidget);
        expect(find.text('2h 30m'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Dark Theme & Accessibility Semantics', () {
    testWidgets('renders properly under dark theme', (tester) async {
      await pumpAtSize(tester, 393.0, brightness: Brightness.dark);

      expect(find.byType(ChildUsagePage), findsOneWidget);
      expect(find.text("Today's Screen Time"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('provides accessible semantic labels for key values', (tester) async {
      await pumpAtSize(tester, 393.0);

      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == "Today's total screen time: 2h 30m",
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'com.standard.app: 1h 0m',
        ),
        findsOneWidget,
      );
    });
  });
}
