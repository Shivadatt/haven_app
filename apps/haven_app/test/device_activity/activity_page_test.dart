import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/core/errors/captured_gaps.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';
import 'page_driver.dart';

/// The usage screen's promise: it renders the rows it read and the reason the
/// rows have no owner, and it never turns an unreadable lane into a number.
void main() {
  final ActivityDriver driver = ActivityDriver();

  tearDown(Get.reset);

  testWidgets('a refused read is the refusal, not an empty shelf', (
    tester,
  ) async {
    await driver.open(tester);

    expect(find.textContaining(ActivityDriver.readGap), findsOneWidget);
    expect(
      find.text('No device has reported a day of use for this family yet.'),
      findsNothing,
    );
  });

  testWidgets('a family that has reported nothing says so plainly', (
    tester,
  ) async {
    await driver.open(tester, repo: FakeActivityRepository(board: board()));

    expect(find.text('0 day-rows read for this family.'), findsOneWidget);
    expect(
      find.text('No device has reported a day of use for this family yet.'),
      findsOneWidget,
    );
  });

  testWidgets('a row shows the app, the total, the day and whose phone', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeActivityRepository(
        board: board(
          lines: [line(app: 'Mapler', deviceName: 'Ivy phone')],
        ),
      ),
    );

    expect(find.text('Mapler'), findsOneWidget);
    expect(find.text('1 h 15 m'), findsOneWidget);
    expect(find.text('1/11/2026 — Ivy phone'), findsOneWidget);
    expect(find.text('last used 2026-11-01T18:04:00.000Z'), findsOneWidget);
  });

  testWidgets('the count is the rows read, not the days that exist', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeActivityRepository(board: board(lines: [line(), line()])),
    );

    expect(find.text('2 day-rows read for this family.'), findsOneWidget);
  });

  testWidgets('the device gap is the captured sentence, word for word', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeActivityRepository(
        board: board(
          lines: [line()],
          deviceGap:
              CapturedGaps.deviceLaneUnavailable<void>().failureOrNull
                  as BlockedFailure,
        ),
      ),
    );

    expect(find.textContaining(CapturedGaps.deviceLaneMissing), findsOneWidget);
    expect(find.text('Ivy phone'), findsNothing);
  });

  testWidgets('readable devices leave no gap notice on the page', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeActivityRepository(
        board: board(lines: [line(deviceName: 'Ivy phone')]),
      ),
    );

    expect(find.textContaining(CapturedGaps.deviceLaneMissing), findsNothing);
  });

  testWidgets('the page states what the list is not', (tester) async {
    await driver.open(
      tester,
      repo: FakeActivityRepository(board: board(lines: [line()])),
    );

    expect(find.text('What this list is not'), findsOneWidget);
    expect(find.textContaining('does not score or rank'), findsOneWidget);
  });

  testWidgets('no family routes to setup and replaces the stack', (
    tester,
  ) async {
    await driver.open(tester, repo: FakeActivityRepository(noFamily: true));

    expect(find.text('Haven is not set up yet'), findsOneWidget);
    await driver.press(tester, 'Start setup');
    expect(driver.routes, [('replace', AppRoutes.onboarding, null)]);
  });

  testWidgets('a retryable failure offers a retry and re-reads', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeActivityRepository(
        failWith: const NetworkFailure('Could not reach the backend.'),
      ),
    );

    expect(find.text('Could not reach the backend.'), findsOneWidget);
    await driver.press(tester, 'Try again', buttonType: FilledButton);
    expect(driver.repository.loadCount, 2);
  });

  testWidgets('a permission refusal offers no retry', (tester) async {
    await driver.open(
      tester,
      repo: FakeActivityRepository(
        failWith: const PermissionFailure('This account cannot read usage.'),
      ),
    );

    expect(find.text('Try again'), findsNothing);
  });
}
