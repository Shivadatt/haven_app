import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/remote_sessions/data/session_detail_models.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';
import 'page_driver.dart';

void main() {
  final SessionsDriver driver = SessionsDriver();

  setUp(() => Get.reset());

  Future<void> open({
    required WidgetTester tester,
    SessionDetail? record,
    String sessionId = 's1',
  }) => driver.openDetail(
    tester,
    repo: FakeSessionsRepository(
      details: record == null ? const {} : {sessionId: record},
    ),
    sessionId: sessionId,
  );

  testWidgets('the record is shown in the words of its own columns', (
    tester,
  ) async {
    await open(
      tester: tester,
      record: sessionDetail(
        record: sessionLine(
          status: 'ended',
          endedReason: 'the child tapped end',
        ),
        signals: [signalLine(fromUserId: 'u1')],
      ),
    );

    expect(find.text('Session record'), findsOneWidget);
    expect(find.text('What the record says'), findsOneWidget);
    expect(find.text('The record says it ended'), findsOneWidget);
    expect(
      find.textContaining('The record said: the child tapped end'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Connection offer · this account sent it'),
      findsOneWidget,
    );
  });

  testWidgets('a running row is not shown as a connection', (tester) async {
    await open(
      tester: tester,
      record: sessionDetail(
        record: sessionLine(status: 'active'),
        signals: [signalLine()],
      ),
    );

    // Two sentences, from two places: the row's own state and the media card's
    // answer. Neither one lets a "running" row read as an observed connection.
    expect(
      find.textContaining('which is not the same as anything reaching a phone'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Nothing in this build carries sound or picture'),
      findsOneWidget,
    );
    expect(find.text('This screen opens nothing.'), findsOneWidget);
  });

  testWidgets('the signalling wall is the captured sentence', (tester) async {
    await open(
      tester: tester,
      record: sessionDetail(signals: [signalLine()]),
    );

    expect(
      find.textContaining('Haven cannot send a signalling row'),
      findsOneWidget,
    );
    expect(
      find.textContaining(SessionsDriver.signalGap),
      findsOneWidget,
      reason: 'the evidence has to be on the page, not only in the repository',
    );
    expect(find.textContaining(SessionsDriver.mediaGap), findsOneWidget);
  });

  testWidgets('the screen offers no control that could only be refused', (
    tester,
  ) async {
    await open(
      tester: tester,
      record: sessionDetail(
        record: sessionLine(status: 'requested'),
        signals: [signalLine()],
      ),
    );

    expect(driver.actionableButtons, 0);
    for (final String label in ['Connect', 'Open the call', 'End it', 'Send']) {
      expect(find.text(label), findsNothing, reason: label);
    }
  });

  testWidgets('an empty buffer is described as empty, not missing', (
    tester,
  ) async {
    await open(tester: tester, record: sessionDetail());

    expect(
      find.text('The read came back with nothing in the buffer.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('These rows are a transport buffer'),
      findsNothing,
    );
  });

  testWidgets('a record this account cannot read is a failure, not a blank', (
    tester,
  ) async {
    await open(tester: tester);

    expect(find.textContaining(SessionsDriver.recordGap), findsOneWidget);
    expect(find.text('Session record'), findsOneWidget);
  });

  testWidgets('a route with no session id says so instead of guessing', (
    tester,
  ) async {
    await open(tester: tester, sessionId: '');

    expect(find.textContaining('No session was named.'), findsOneWidget);
    expect(driver.repository.detailCount, 0);
  });

  testWidgets('a network failure is not filed as a specification gap', (
    tester,
  ) async {
    await driver.openDetail(
      tester,
      repo: FakeSessionsRepository(failWith: const NetworkFailure('Offline.')),
    );

    expect(find.textContaining('Offline.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('no family routes the parent to setup', (tester) async {
    await driver.openDetail(
      tester,
      repo: FakeSessionsRepository(noFamily: true),
    );

    await driver.press(tester, SessionsDriver.setup);

    expect(driver.routes, [('replace', AppRoutes.onboarding, null)]);
  });
}
