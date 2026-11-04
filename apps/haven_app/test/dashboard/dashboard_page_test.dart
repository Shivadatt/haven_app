import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_core/haven_core.dart';

import '../family/fakes.dart';
import 'fakes.dart';
import 'page_driver.dart';

void main() {
  final driver = DashboardDriver();
  tearDown(Get.reset);

  testWidgets('the family is described in counts the app actually read', (
    tester,
  ) async {
    await driver.open(
      tester,
      data: driver.sampleData(
        family: bundle(
          children: [child('c1', 'Ivy')],
          parents: [parent('u1', 'Rae'), parent('u2', 'Sam')],
        ),
      ),
    );

    expect(find.text('Rivera'), findsOneWidget);
    expect(find.text('1 child and 2 parents in this family.'), findsOneWidget);
    expect(find.text('Ivy'), findsOneWidget);
  });

  testWidgets('the device section is a refusal, never an empty list', (
    tester,
  ) async {
    await driver.open(tester, data: driver.sampleData());

    // The page renders whatever the repository's BlockedFailure says, so these
    // words come from the fake seam: proof the screen has no invented copy and
    // no dead device list of its own.
    expect(find.text('fake: no device list'), findsOneWidget);
    expect(find.textContaining('F6'), findsOneWidget);
  });

  testWidgets('a family with no children yet says so plainly', (tester) async {
    await driver.open(tester, data: driver.sampleData(family: bundle()));

    expect(
      find.textContaining('No children are in this family yet'),
      findsOneWidget,
    );
  });

  testWidgets('the ways onward go where they say', (tester) async {
    await driver.open(tester, data: driver.sampleData());

    await driver.press(tester, 'Open your family', buttonType: OutlinedButton);
    await tester.ensureVisible(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(driver.routes, [
      ('push', AppRoutes.family, null),
      ('push', AppRoutes.settings, null),
    ]);
  });

  testWidgets('the named places have a way onward, outside the device wall', (
    tester,
  ) async {
    await driver.open(tester, data: driver.sampleData());

    // A working write listed under a refusal reads as a refusal, so the places
    // entry sits in its own card rather than under the device gap.
    expect(find.text('Safe places'), findsOneWidget);
    await driver.press(tester, 'Open safe places', buttonType: OutlinedButton);

    expect(driver.routes.last, ('push', AppRoutes.safeZones, null));
  });

  testWidgets('a child opens its own page', (tester) async {
    await driver.open(tester, data: driver.sampleData());

    await tester.tap(find.text('Ivy'));
    await tester.pumpAndSettle();

    expect(driver.routes, [('push', AppRoutes.childProfile, 'c1')]);
  });

  testWidgets('the records a parent can read have ways onward', (tester) async {
    await driver.open(tester, data: driver.sampleData());

    // Instructions, rule versions and session records are three reads of three
    // tables, and the full report list is the fourth. Each is a working
    // navigation, not a promise about a row.
    await driver.press(
      tester,
      'Open session records',
      buttonType: OutlinedButton,
    );
    await driver.press(
      tester,
      'Open the full list',
      buttonType: OutlinedButton,
    );

    expect(driver.routes, [
      ('push', AppRoutes.remoteSessions, null),
      ('push', AppRoutes.notifications, null),
    ]);
  });

  testWidgets('no family is sent to setup, replacing the stack', (
    tester,
  ) async {
    await driver.open(tester);

    expect(find.text('Haven is not set up yet'), findsOneWidget);
    expect(find.text('Open your family'), findsNothing);

    await driver.press(tester, 'Start setup');

    expect(driver.routes, [('replace', AppRoutes.onboarding, null)]);
  });

  testWidgets('a failed read is retried, not left blank', (tester) async {
    await driver.open(
      tester,
      repo: FakeDashboardRepository()
        ..loadFailWith = const NetworkFailure('No connection.'),
    );

    expect(find.textContaining('No connection'), findsOneWidget);

    driver.repository.loadFailWith = null;
    driver.repository.data = driver.sampleData();
    await driver.press(tester, 'Try again');

    expect(find.text('Rivera'), findsOneWidget);
  });
}
