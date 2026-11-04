import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';
import 'page_driver.dart';

/// One device, three separate missing grants. Collapsing them would hide which
/// one an owner has to settle, so the test checks each sentence arrives.
void main() {
  final driver = DevicesDriver();

  tearDown(Get.reset);

  testWidgets('the record and both actions each state their own gap', (
    tester,
  ) async {
    await driver.openDetail(tester);

    expect(find.textContaining(DevicesDriver.recordGap), findsOneWidget);
    expect(
      find.textContaining('no contract for revoking a device'),
      findsOneWidget,
    );
    expect(
      find.textContaining('no contract for asking a device to re-check'),
      findsOneWidget,
    );
  });

  testWidgets('a refusal is not dressed up as a device with no information', (
    tester,
  ) async {
    await driver.openDetail(tester);

    expect(find.text('What this device is'), findsOneWidget);
    expect(
      find.textContaining('The backend returned no device for this id'),
      findsNothing,
    );
  });

  testWidgets('a device the backend did answer about is rendered', (
    tester,
  ) async {
    await driver.openDetail(
      tester,
      repo: FakeDevicesRepository(record: device('d1', name: 'Ivy phone')),
    );

    expect(find.text('Ivy phone'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    // The actions are still refused even when the record read worked: they are
    // different grants, and a readable row does not make them executable.
    expect(
      find.textContaining('no contract for revoking a device'),
      findsOneWidget,
    );
  });

  testWidgets('a retryable fault offers the retry the fault asked for', (
    tester,
  ) async {
    await driver.openDetail(
      tester,
      repo: FakeDevicesRepository()
        ..recordFailWith = const NetworkFailure('No connection.'),
    );

    expect(find.text('No connection.'), findsOneWidget);

    await driver.press(tester, 'Try again');
    expect(
      driver.repository.calls.where((String c) => c == 'device').length,
      2,
    );
  });

  testWidgets('a refusal the backend would not repeat has no retry button', (
    tester,
  ) async {
    await driver.openDetail(
      tester,
      repo: FakeDevicesRepository()
        ..recordFailWith = const PermissionFailure(
          'Row-level security refused.',
        ),
    );

    expect(find.text('Row-level security refused.'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('a screen opened without a device named reads nothing', (
    tester,
  ) async {
    await driver.openDetail(tester, deviceId: '');

    expect(find.text('No device was named'), findsOneWidget);
    expect(driver.repository.calls, isEmpty);
  });
}
