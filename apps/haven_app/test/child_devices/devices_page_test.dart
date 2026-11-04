import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/routes/app_routes.dart';

import 'fakes.dart';
import 'page_driver.dart';

/// The list screen's promise: a refusal is shown as a refusal. "Nothing is
/// paired" is only ever said when the backend actually returned an empty list.
void main() {
  final driver = DevicesDriver();

  tearDown(Get.reset);

  testWidgets('a refused read is the refusal, not an empty shelf', (
    tester,
  ) async {
    await driver.openList(tester);

    expect(find.textContaining(DevicesDriver.listGap), findsOneWidget);
    expect(find.text('No device is paired yet'), findsNothing);
  });

  testWidgets('an empty list is said as an empty list', (tester) async {
    await driver.openList(
      tester,
      repo: FakeDevicesRepository(devices: const []),
    );

    expect(find.text('No device is paired yet'), findsOneWidget);
    expect(find.textContaining(DevicesDriver.listGap), findsNothing);
  });

  testWidgets('a paired device is named, dated and statused from its row', (
    tester,
  ) async {
    await driver.openList(
      tester,
      repo: FakeDevicesRepository(devices: [device('d1', name: 'Ivy phone')]),
    );

    expect(find.text('Ivy phone'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.textContaining('Last seen'), findsOneWidget);
    expect(find.text('1 device read from the backend.'), findsOneWidget);
  });

  testWidgets('a device the backend has never heard from says so', (
    tester,
  ) async {
    await driver.openList(
      tester,
      repo: FakeDevicesRepository(
        devices: [
          device('d1', name: '', lastSeenAt: ''),
          device('d2', status: 'pending'),
        ],
      ),
    );

    expect(find.text('A device with no name yet'), findsOneWidget);
    expect(
      find.text('The backend has not reported hearing from it'),
      findsOneWidget,
    );
    expect(find.text('Waiting to be set up'), findsOneWidget);
  });

  testWidgets('a revoked device is history, not a fault', (tester) async {
    await driver.openList(
      tester,
      repo: FakeDevicesRepository(devices: [device('d1', status: 'revoked')]),
    );

    expect(find.text('Removed'), findsOneWidget);
  });

  testWidgets('no secret material from the row reaches the screen', (
    tester,
  ) async {
    await driver.openList(
      tester,
      repo: FakeDevicesRepository(devices: [device('d1')]),
    );

    expect(find.textContaining('never-shown'), findsNothing);
    expect(find.textContaining('secret'), findsNothing);
  });

  testWidgets('open pairing is a route, not a dead button', (tester) async {
    // A read that answered: when the list is refused the page shows the refusal
    // alone, and the refusal is the thing the parent has to act on.
    await driver.openList(
      tester,
      repo: FakeDevicesRepository(devices: const []),
    );

    await driver.press(tester, 'Open pairing', buttonType: OutlinedButton);

    expect(driver.routes, [('push', AppRoutes.pairing, null)]);
  });
}
