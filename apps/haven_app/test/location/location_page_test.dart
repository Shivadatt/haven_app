import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/core/errors/captured_gaps.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';
import 'page_driver.dart';

/// The location screen's promise: it reports the fixes it read, keeps the
/// coordinates hidden until asked, and states the two things it cannot say.
void main() {
  final LocationDriver driver = LocationDriver();

  tearDown(Get.reset);

  testWidgets('a refused read is the refusal, not an empty shelf', (
    tester,
  ) async {
    await driver.open(tester);

    expect(find.textContaining(LocationDriver.readGap), findsOneWidget);
    expect(
      find.text('No device has reported a place for this family yet.'),
      findsNothing,
    );
  });

  testWidgets('a family that has reported nothing says so plainly', (
    tester,
  ) async {
    await driver.open(tester, repo: FakeLocationRepository(board: board()));

    expect(
      find.text('No device has reported a place for this family yet.'),
      findsOneWidget,
    );
  });

  testWidgets('a fix shows whose, when, and how wide the device says it is', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeLocationRepository(
        board: board(lines: [fixLine(deviceName: 'Ivy phone')]),
      ),
    );

    expect(find.text('Ivy phone'), findsOneWidget);
    expect(
      find.text('reported at 2026-11-01T09:00:00.000Z — to within about 12 m'),
      findsOneWidget,
    );
    expect(find.text('reached Haven within a minute'), findsOneWidget);
  });

  testWidgets('coordinates stay hidden until the parent asks', (tester) async {
    await driver.open(
      tester,
      repo: FakeLocationRepository(board: board(lines: [fixLine()])),
    );

    expect(find.text('37.7749, -122.4194'), findsNothing);
    expect(find.text(LocationDriver.showCoords), findsOneWidget);

    await driver.press(
      tester,
      LocationDriver.showCoords,
      buttonType: OutlinedButton,
    );
    expect(find.textContaining('37.7749, -122.4194'), findsOneWidget);
    expect(find.textContaining('as reported by fused'), findsOneWidget);

    await driver.press(
      tester,
      LocationDriver.hideCoords,
      buttonType: OutlinedButton,
    );
    expect(find.textContaining('37.7749, -122.4194'), findsNothing);
  });

  testWidgets('no reveal control is offered when nothing was read', (
    tester,
  ) async {
    await driver.open(tester, repo: FakeLocationRepository(board: board()));

    expect(find.text(LocationDriver.showCoords), findsNothing);
  });

  testWidgets('the presence boundary is stated, not worked around', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeLocationRepository(board: board(lines: [fixLine()])),
    );

    expect(
      find.textContaining(CapturedGaps.presenceLaneMissing),
      findsOneWidget,
    );
    expect(find.textContaining('inside a safe place'), findsOneWidget);
  });

  testWidgets('the device gap is the captured sentence, word for word', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeLocationRepository(
        board: board(
          lines: [fixLine()],
          deviceGap:
              CapturedGaps.deviceLaneUnavailable<void>().failureOrNull
                  as BlockedFailure,
        ),
      ),
    );

    expect(find.textContaining(CapturedGaps.deviceLaneMissing), findsOneWidget);
    expect(find.text('Ivy phone'), findsNothing);
  });

  testWidgets('the page says plainly that this is not a map', (tester) async {
    await driver.open(
      tester,
      repo: FakeLocationRepository(board: board(lines: [fixLine()])),
    );

    expect(find.text('What these places are not'), findsOneWidget);
    expect(find.textContaining('does not show a map'), findsOneWidget);
  });

  testWidgets('no family routes to setup and replaces the stack', (
    tester,
  ) async {
    await driver.open(tester, repo: FakeLocationRepository(noFamily: true));

    expect(find.text('Haven is not set up yet'), findsOneWidget);
    await driver.press(tester, 'Start setup');
    expect(driver.routes, [('replace', AppRoutes.onboarding, null)]);
  });

  testWidgets('a retryable failure offers a retry and re-reads', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeLocationRepository(
        failWith: const NetworkFailure('Could not reach the backend.'),
      ),
    );

    expect(find.text('Could not reach the backend.'), findsOneWidget);
    await driver.press(tester, 'Try again');
    expect(driver.repository.loadCount, 2);
  });

  testWidgets('a narrowed read is labelled as narrowed', (tester) async {
    await driver.open(
      tester,
      repo: FakeLocationRepository(
        board: board(lines: [fixLine()], deviceId: 'd1'),
      ),
      deviceId: 'd1',
    );

    expect(find.textContaining('for one device.'), findsOneWidget);
    expect(driver.repository.lastDeviceId, 'd1');
  });
}
