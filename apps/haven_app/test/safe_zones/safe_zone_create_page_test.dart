import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_app/features/safe_zones/controllers/zone_create_controller.dart';
import 'package:haven_app/features/safe_zones/views/pages/safe_zone_create_page.dart';

import 'fakes.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('SafeZoneCreatePage allows input, radius stepper/slider and creation', (
    tester,
  ) async {
    final fakeRepo = FakeSafeZonesRepository(board: board());
    final controller = SafeZoneCreateController(repository: fakeRepo);
    Get.put<SafeZoneCreateController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        home: const SafeZoneCreatePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add a safe place'), findsOneWidget);
    expect(find.text('Place Name'), findsOneWidget);
    expect(find.text('Latitude'), findsOneWidget);
    expect(find.text('Longitude'), findsOneWidget);
    expect(find.text('Radius: 150 m'), findsOneWidget);

    // Test radius stepper
    final increaseButton = find.byTooltip('Increase 50m');
    await tester.tap(increaseButton);
    await tester.pumpAndSettle();
    expect(controller.radiusM.value, 200.0);
    expect(find.text('Radius: 200 m'), findsOneWidget);

    final decreaseButton = find.byTooltip('Decrease 50m');
    await tester.tap(decreaseButton);
    await tester.pumpAndSettle();
    expect(controller.radiusM.value, 150.0);

    // Enter fields
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Community Center');
    await tester.enterText(fields.at(1), '37.7749');
    await tester.enterText(fields.at(2), '-122.4194');
    await tester.pumpAndSettle();

    expect(controller.isValid, isTrue);

    // Tap Create safe place
    final createButton = find.widgetWithText(HavenButton, 'Create safe place');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(fakeRepo.createCount, 1);
  });
}
