import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/policies/data/policies_repository.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';
import 'page_driver.dart';

void main() {
  final PoliciesDriver driver = PoliciesDriver();

  setUp(() => Get.reset());

  testWidgets('a version shows its number, its state and whose device', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakePoliciesRepository(
        board: policyBoard(
          lines: [
            policyLine(
              version: 9,
              enforcementStatus: 'enforced',
              acknowledgedAt: '2026-11-01T09:30:00.000Z',
            ),
          ],
        ),
      ),
    );

    expect(find.textContaining('Version 9 ·'), findsOneWidget);
    expect(find.text('Applied on the device'), findsOneWidget);
    expect(
      find.textContaining('The device said it applied this version'),
      findsOneWidget,
    );
    expect(
      find.textContaining('answered 2026-11-01T09:30:00.000Z'),
      findsOneWidget,
    );
  });

  testWidgets('the screen offers no way to write, because none could succeed', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakePoliciesRepository(board: policyBoard(lines: [policyLine()])),
    );

    expect(driver.actionableButtons, 0);
    expect(find.text('Apply this version'), findsNothing);
    expect(find.text('New rules'), findsNothing);
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('both refusals are the captured sentences, not paraphrases', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakePoliciesRepository(board: policyBoard(lines: [policyLine()])),
    );

    expect(
      find.textContaining(HavenPoliciesRepository.writeMissing),
      findsOneWidget,
    );
    expect(
      find.textContaining(HavenPoliciesRepository.ruleShapeMissing),
      findsOneWidget,
      reason:
          'the page has to say the rule shape is unspecified rather than '
          'leave the parent to wonder why a version shows no rules',
    );
  });

  testWidgets('a written version is never presented as a live rule', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakePoliciesRepository(
        board: policyBoard(lines: [policyLine(version: 3)]),
      ),
    );

    expect(
      find.textContaining('A number here is not the set of rules'),
      findsOneWidget,
    );
    expect(find.textContaining('0 of 1 carry an answer'), findsOneWidget);
  });

  testWidgets(
    'a device refusal is shown beside the versions it leaves unnamed',
    (tester) async {
      final BlockedFailure gap =
          blocked<void>('fake: device rows unreadable here').failureOrNull!
              as BlockedFailure;
      await driver.open(
        tester,
        repo: FakePoliciesRepository(
          board: policyBoard(lines: [policyLine()], deviceGap: gap),
        ),
      );

      expect(
        find.textContaining('fake: device rows unreadable here'),
        findsOneWidget,
      );
    },
  );

  testWidgets('an empty list is stated as a read that found nothing', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakePoliciesRepository(board: policyBoard()),
    );

    expect(find.text(PoliciesDriver.emptyLine), findsOneWidget);
    expect(
      find.textContaining(HavenPoliciesRepository.ruleShapeMissing),
      findsOneWidget,
    );
  });

  testWidgets('a refused read is reported, not shown as an empty list', (
    tester,
  ) async {
    await driver.open(tester);

    expect(find.textContaining(PoliciesDriver.readGap), findsOneWidget);
    expect(find.text(PoliciesDriver.emptyLine), findsNothing);
  });

  testWidgets('no family routes the parent to setup', (tester) async {
    await driver.open(tester, repo: FakePoliciesRepository(noFamily: true));

    await driver.press(tester, PoliciesDriver.setup);

    expect(driver.routes, [('replace', AppRoutes.onboarding, null)]);
  });

  testWidgets('a device id in the route reaches the read', (tester) async {
    await driver.open(
      tester,
      repo: FakePoliciesRepository(
        board: policyBoard(deviceId: 'd7', lines: [policyLine()]),
      ),
      deviceId: 'd7',
    );

    expect(driver.repository.lastDeviceId, 'd7');
    expect(find.textContaining('one device'), findsOneWidget);
  });
}
