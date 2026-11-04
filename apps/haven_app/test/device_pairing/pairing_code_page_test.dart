import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/routes/app_routes.dart';

import 'fakes.dart';
import 'page_driver.dart';

/// The screen that would start a pairing. It has no code box and no invite
/// button, and that absence is the promise being tested: §2 of the build
/// contract forbids a control that can only ever be refused.
void main() {
  final driver = PairingDriver();

  tearDown(Get.reset);

  testWidgets('both ways in are explained as refusals', (tester) async {
    await driver.openCode(tester);

    expect(find.text('A short code from the phone'), findsOneWidget);
    expect(find.text('An invite for a Child ID'), findsOneWidget);
    expect(
      find.textContaining('no contract for accepting a code'),
      findsOneWidget,
    );
    expect(
      find.textContaining('no contract for starting an invite'),
      findsOneWidget,
    );
  });

  testWidgets('there is nothing to type a code into', (tester) async {
    await driver.openCode(tester);

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Pair this device'), findsNothing);
  });

  testWidgets('the child still has to say yes', (tester) async {
    await driver.openCode(tester);

    expect(
      find.textContaining('the child approves on their own phone'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a screen opened for another family says so before anything else',
    (tester) async {
      await driver.openCode(tester, familyId: 'f9');

      expect(
        find.text('This pairing screen was opened for another family'),
        findsOneWidget,
      );
      // The name is the one the family read returned, not one the page invented.
      expect(
        find.textContaining('Pairing would belong to Rivera'),
        findsOneWidget,
      );
    },
  );

  testWidgets('back to pairing is a route, not a dead button', (tester) async {
    await driver.openCode(tester, familyId: 'f9');

    await driver.press(tester, 'Back to pairing');

    expect(driver.routes, [('to', AppRoutes.pairing, null)]);
  });

  testWidgets('no family to pair into is its own honest state', (tester) async {
    await driver.openCode(tester, repo: FakePairingRepository());

    expect(find.text('There is no family to pair into yet'), findsOneWidget);
    expect(
      find.textContaining('no contract for accepting a code'),
      findsNothing,
    );
  });
}
