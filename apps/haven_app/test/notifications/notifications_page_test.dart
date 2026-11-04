import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';
import 'page_driver.dart';

void main() {
  final ReportsDriver driver = ReportsDriver();

  setUp(() => Get.reset());

  testWidgets('a row shows the sentence the backend wrote, in its own words', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeAlertsRepository(
        board: alertBoard(
          lines: [
            alertLine(
              deviceName: 'Ivy',
              message: 'Ivy left School at 12:04',
              severity: 'critical',
              acknowledged: true,
              payload: const {'zone': 'School'},
            ),
          ],
        ),
      ),
    );

    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Ivy left School at 12:04'), findsOneWidget);
    expect(find.text('Needs attention now'), findsOneWidget);
    expect(
      find.textContaining('Ivy · at 2026-11-01T09:00:00.000Z'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Recorded as: Left a safe place'),
      findsOneWidget,
    );
    expect(
      find.textContaining('1 item stored with it, not shown here'),
      findsOneWidget,
    );
  });

  testWidgets('the screen offers no control that could only be refused', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeAlertsRepository(board: alertBoard(lines: [alertLine()])),
    );

    // The one enabled control opens the settings screen, which works. Nothing
    // here claims to mark a row or subscribe the phone.
    expect(driver.actionableButtons, 1);
    for (final String label in [
      'Mark as read',
      'Dismiss',
      'Clear all',
      'Allow notifications',
      'Subscribe',
    ]) {
      expect(find.text(label), findsNothing, reason: label);
    }
  });

  testWidgets('the attention sentence follows the rows, not a mood', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeAlertsRepository(
        board: alertBoard(lines: [alertLine(severity: 'info')]),
      ),
    );

    expect(
      find.textContaining(
        'None of the rows read is marked as needing attention',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('are marked as needing attention now'),
      findsNothing,
    );
  });

  testWidgets('a read that found nothing says so without hiding the walls', (
    tester,
  ) async {
    await driver.open(tester, repo: FakeAlertsRepository(board: alertBoard()));

    expect(find.text(ReportsDriver.emptyLine), findsOneWidget);
    expect(find.textContaining(ReportsDriver.ackGap), findsOneWidget);
    expect(
      find.textContaining('are marked as answered in the record'),
      findsNothing,
    );
  });

  testWidgets('a refused read is reported, not shown as an empty list', (
    tester,
  ) async {
    await driver.open(tester);

    expect(find.textContaining(ReportsDriver.readGap), findsOneWidget);
    expect(find.text(ReportsDriver.emptyLine), findsNothing);
  });

  testWidgets('the addressee stays unnamed and its refusal is on the page', (
    tester,
  ) async {
    final BlockedFailure gap =
        blocked<void>('fake: device rows unreadable here').failureOrNull!
            as BlockedFailure;
    await driver.open(
      tester,
      repo: FakeAlertsRepository(
        board: alertBoard(lines: [alertLine()], deviceGap: gap),
      ),
    );

    expect(
      find.textContaining('fake: device rows unreadable here'),
      findsOneWidget,
    );
    expect(
      find.textContaining('a device this build cannot name'),
      findsOneWidget,
    );
  });

  testWidgets('a network failure is retryable, not a specification gap', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeAlertsRepository(failWith: const NetworkFailure('Offline.')),
    );

    expect(find.textContaining('Offline.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('no family routes the parent to setup', (tester) async {
    await driver.open(tester, repo: FakeAlertsRepository(noFamily: true));

    await driver.press(tester, ReportsDriver.setup);

    expect(driver.routes, [('replace', AppRoutes.onboarding, null)]);
  });

  testWidgets('a feed hint re-reads the list in place', (tester) async {
    await driver.open(
      tester,
      repo: FakeAlertsRepository(board: alertBoard()),
      withFeed: true,
    );
    expect(driver.repository.loadCount, 1);

    driver.feed.emit(TableName.safetyAlerts, {
      'id': 'a9',
      'message': 'fabricated',
    });
    await tester.pumpAndSettle();

    expect(driver.repository.loadCount, 2);
    // The hint never becomes a row: the screen still shows what the read gave.
    expect(find.text('fabricated'), findsNothing);
  });
}
