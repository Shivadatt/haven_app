import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/routes/app_routes.dart';

import 'fakes.dart';
import 'page_driver.dart';

/// The limits card on the reports screen, held apart from the list because it
/// makes the opposite promise: the list says what was read, and this says what
/// cannot be done and why.
void main() {
  final ReportsDriver driver = ReportsDriver();

  setUp(() => Get.reset());

  testWidgets('both refusals are the captured sentences, not paraphrases', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeAlertsRepository(board: alertBoard(lines: [alertLine()])),
    );

    expect(
      find.textContaining('Haven cannot mark a report as read or answered'),
      findsOneWidget,
    );
    expect(
      find.textContaining(ReportsDriver.ackGap),
      findsOneWidget,
      reason: 'the evidence has to be on the page, not only in the repository',
    );
    expect(
      find.textContaining('Haven cannot register this device to be pushed to'),
      findsOneWidget,
    );
    expect(find.textContaining(ReportsDriver.deliveryGap), findsOneWidget);
  });

  testWidgets('the list says it is a read, not a delivery', (tester) async {
    await driver.open(
      tester,
      repo: FakeAlertsRepository(board: alertBoard(lines: [alertLine()])),
    );

    expect(
      find.textContaining(
        'Nothing has registered this phone to be sent a notification',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'asked on the settings screen, which owns that question',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a registered device drops the sentence that no longer applies', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeAlertsRepository(board: alertBoard(lines: [alertLine()])),
      delivery: RegisteredDelivery(),
    );

    expect(
      find.textContaining('Nothing has registered this phone'),
      findsNothing,
    );
    // The two walls stay: registering is not the same as being able to mark a row.
    expect(find.textContaining(ReportsDriver.ackGap), findsOneWidget);
  });

  testWidgets('the permission question opens the screen that owns it', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeAlertsRepository(board: alertBoard(lines: [alertLine()])),
    );

    await driver.press(tester, ReportsDriver.openSettings);

    expect(driver.routes, [('push', AppRoutes.settings, null)]);
  });
}
