import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';
import 'page_driver.dart';

void main() {
  final SessionsDriver driver = SessionsDriver();

  setUp(() => Get.reset());

  testWidgets('a row says what was asked, where it stands and what is marked', (
    tester,
  ) async {
    await driver.openList(
      tester,
      repo: FakeSessionsRepository(
        board: sessionBoard(lines: [sessionLine(status: 'active')]),
      ),
    );

    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('A request for a video session'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(
      find.textContaining('Consent is recorded as given on this row'),
      findsOneWidget,
    );
    expect(
      find.textContaining('a device this build cannot name'),
      findsOneWidget,
    );
    expect(
      find.textContaining('requested 2026-11-01T09:00:00.000Z'),
      findsOneWidget,
    );
    // The list keeps an open row in the record's own words, not a claim.
    expect(
      find.textContaining('1 of 1 are still open in the record'),
      findsOneWidget,
    );
  });

  testWidgets('an open row with no consent mark is not shown as ordinary', (
    tester,
  ) async {
    await driver.openList(
      tester,
      repo: FakeSessionsRepository(
        board: sessionBoard(
          lines: [
            sessionLine(id: 's1', status: 'active', consentRecorded: false),
          ],
        ),
      ),
    );

    expect(
      find.textContaining('Nothing on this row records consent'),
      findsOneWidget,
    );
    expect(
      find.textContaining('1 open row carries no consent mark'),
      findsOneWidget,
    );
  });

  testWidgets('the screen offers no control that could only be refused', (
    tester,
  ) async {
    await driver.openList(
      tester,
      repo: FakeSessionsRepository(board: sessionBoard(lines: [sessionLine()])),
    );

    // The one enabled control on a row navigates to a record the backend
    // returned; nothing here claims to move a session.
    expect(driver.actionableButtons, 1);
    for (final String label in [
      'Start a session',
      'Accept',
      'Decline',
      'End it',
      'Connect',
    ]) {
      expect(find.text(label), findsNothing, reason: label);
    }
  });

  testWidgets('both refusals are the captured sentences, not paraphrases', (
    tester,
  ) async {
    await driver.openList(
      tester,
      repo: FakeSessionsRepository(board: sessionBoard(lines: [sessionLine()])),
    );

    expect(
      find.textContaining('Haven cannot ask for, answer or retire a session'),
      findsOneWidget,
    );
    expect(
      find.textContaining(SessionsDriver.startGap),
      findsOneWidget,
      reason: 'the evidence has to be on the page, not only in the repository',
    );
    expect(
      find.textContaining('Haven cannot open the audio or video path'),
      findsOneWidget,
    );
    expect(find.textContaining(SessionsDriver.mediaGap), findsOneWidget);
  });

  testWidgets('a read that found nothing says so without hiding the wall', (
    tester,
  ) async {
    await driver.openList(
      tester,
      repo: FakeSessionsRepository(board: sessionBoard()),
    );

    expect(find.text(SessionsDriver.emptyList), findsOneWidget);
    expect(find.textContaining(SessionsDriver.startGap), findsOneWidget);
    expect(find.textContaining('are still open in the record'), findsNothing);
  });

  testWidgets('a refused read is reported, not shown as an empty list', (
    tester,
  ) async {
    await driver.openList(tester);

    expect(find.textContaining(SessionsDriver.readGap), findsOneWidget);
    expect(find.text(SessionsDriver.emptyList), findsNothing);
  });

  testWidgets('the addressee stays unnamed and its refusal is on the page', (
    tester,
  ) async {
    final BlockedFailure gap =
        blocked<void>('fake: device rows unreadable here').failureOrNull!
            as BlockedFailure;
    await driver.openList(
      tester,
      repo: FakeSessionsRepository(
        board: sessionBoard(lines: [sessionLine()], deviceGap: gap),
      ),
    );

    expect(
      find.textContaining('fake: device rows unreadable here'),
      findsOneWidget,
    );
  });

  testWidgets('opening a record pushes the detail route with its id', (
    tester,
  ) async {
    await driver.openList(
      tester,
      repo: FakeSessionsRepository(
        board: sessionBoard(lines: [sessionLine(id: 's1')]),
      ),
    );

    await driver.press(tester, 'Open this record');

    expect(driver.routes, [('push', AppRoutes.remoteSessionDetail, 's1')]);
  });

  testWidgets('no family routes the parent to setup', (tester) async {
    await driver.openList(tester, repo: FakeSessionsRepository(noFamily: true));

    await driver.press(tester, SessionsDriver.setup);

    expect(driver.routes, [('replace', AppRoutes.onboarding, null)]);
  });

  testWidgets('a feed hint re-reads the list in place', (tester) async {
    await driver.openList(
      tester,
      repo: FakeSessionsRepository(board: sessionBoard()),
      withFeed: true,
    );
    expect(driver.repository.loadCount, 1);

    driver.feed.emit(TableName.remoteSessions, {'id': 's1'});
    await tester.pumpAndSettle();

    expect(driver.repository.loadCount, 2);
    expect(find.text('Sessions'), findsOneWidget);
  });
}
