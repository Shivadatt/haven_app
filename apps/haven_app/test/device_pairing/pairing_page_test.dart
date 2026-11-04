import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';
import 'page_driver.dart';

void main() {
  final driver = PairingDriver();

  tearDown(Get.reset);

  testWidgets('the requests this family may read are listed', (tester) async {
    await driver.openPairing(
      tester,
      repo: FakePairingRepository(
        board: board(
          lines: [
            line('r1', 'Ivy'),
            line('r2', 'Kai', status: 'approved'),
          ],
        ),
      ),
    );

    expect(find.text('Ivy'), findsOneWidget);
    expect(find.text('Kai'), findsOneWidget);
    expect(find.text('Waiting for approval'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    // The count is of what was read, never of what is believed to exist.
    expect(
      find.text('2 requests read, 1 waiting on the child.'),
      findsOneWidget,
    );
  });

  testWidgets('a waiting request is followed by the refusal, not a button', (
    tester,
  ) async {
    await driver.openPairing(
      tester,
      repo: FakePairingRepository(board: board(lines: [line('r1', 'Ivy')])),
    );

    expect(
      find.textContaining('no contract for withdrawing a request'),
      findsOneWidget,
    );
    expect(find.text('Withdraw'), findsNothing);
  });

  testWidgets('nothing waiting means no withdrawal refusal either', (
    tester,
  ) async {
    await driver.openPairing(
      tester,
      repo: FakePairingRepository(
        board: board(
          lines: [line('r1', 'Ivy', status: 'approved', responded: true)],
        ),
      ),
    );

    expect(find.textContaining('withdrawing a request'), findsNothing);
  });

  testWidgets('an empty list is said plainly, with the road onward kept', (
    tester,
  ) async {
    await driver.openPairing(tester);

    expect(
      find.textContaining('Nothing has been requested for this family yet'),
      findsOneWidget,
    );
    expect(find.text('How pairing works'), findsOneWidget);
  });

  testWidgets('how pairing works is a real route carrying the family read', (
    tester,
  ) async {
    await driver.openPairing(tester);

    await driver.press(tester, 'How pairing works', buttonType: OutlinedButton);

    expect(driver.routes, [('push', AppRoutes.pairingCode, 'f1')]);
  });

  testWidgets('no family is offered setup instead of a list', (tester) async {
    await driver.openPairing(tester, repo: FakePairingRepository());

    expect(find.text('Haven is not set up yet'), findsOneWidget);

    await driver.press(tester, 'Start setup');
    expect(driver.routes, [('replace', AppRoutes.onboarding, null)]);
  });

  testWidgets('a refused read offers a retry, not an empty pairing screen', (
    tester,
  ) async {
    await driver.openPairing(
      tester,
      repo: FakePairingRepository()
        ..loadFailWith = const NetworkFailure('No connection.'),
    );

    expect(find.text('No connection.'), findsOneWidget);
    expect(find.text('Start setup'), findsNothing);

    await driver.press(tester, 'Try again');
    expect(driver.repository.calls.where((String c) => c == 'load').length, 2);
  });
}
