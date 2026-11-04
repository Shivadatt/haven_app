import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/device_commands/data/commands_repository.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';
import 'page_driver.dart';

void main() {
  final CommandsDriver driver = CommandsDriver();

  setUp(() => Get.reset());

  testWidgets('a row shows the ask, the state and who it went to', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeCommandsRepository(
        board: cmdBoard(
          lines: [
            commandLine(
              type: 'apply_policy',
              status: 'succeeded',
              ackedAt: '2026-11-01T09:05:00.000Z',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Apply the current rules'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(
      find.textContaining('The device answered that it is done'),
      findsOneWidget,
    );
    expect(
      find.textContaining('a device this build cannot name'),
      findsOneWidget,
    );
    expect(find.text('1 of 1 carry an answer from a device.'), findsOneWidget);
  });

  testWidgets('the log offers no control that could only be refused', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeCommandsRepository(board: cmdBoard(lines: [commandLine()])),
    );

    expect(driver.actionableButtons, 0);
    expect(find.text('Send'), findsNothing);
    expect(find.text('Retry it'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Mark as done'), findsNothing);
  });

  testWidgets('the write refusal is the captured sentence, not a paraphrase', (
    tester,
  ) async {
    await driver.open(
      tester,
      repo: FakeCommandsRepository(board: cmdBoard(lines: [commandLine()])),
    );

    expect(
      find.textContaining(
        'Haven cannot send, cancel or answer an instruction in this build yet.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(HavenCommandsRepository.writeMissing),
      findsOneWidget,
      reason: 'the evidence has to be on the page, not only in the repository',
    );
  });

  testWidgets('a device refusal is shown beside the rows it leaves unnamed', (
    tester,
  ) async {
    final BlockedFailure gap =
        blocked<void>('fake: device rows unreadable here').failureOrNull!
            as BlockedFailure;
    await driver.open(
      tester,
      repo: FakeCommandsRepository(
        board: cmdBoard(lines: [commandLine()], deviceGap: gap),
      ),
    );

    expect(
      find.textContaining('fake: device rows unreadable here'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a read that found nothing says so without hiding the write wall',
    (tester) async {
      await driver.open(
        tester,
        repo: FakeCommandsRepository(board: cmdBoard()),
      );

      expect(find.text(CommandsDriver.emptyLine), findsOneWidget);
      expect(
        find.textContaining(HavenCommandsRepository.writeMissing),
        findsOneWidget,
      );
    },
  );

  testWidgets('a refused read is reported, not shown as an empty log', (
    tester,
  ) async {
    await driver.open(tester);

    expect(find.textContaining(CommandsDriver.readGap), findsOneWidget);
    expect(find.text(CommandsDriver.emptyLine), findsNothing);
  });

  testWidgets('no family routes the parent to setup', (tester) async {
    await driver.open(tester, repo: FakeCommandsRepository(noFamily: true));

    await driver.press(tester, CommandsDriver.setup);

    expect(driver.routes, [('replace', AppRoutes.onboarding, null)]);
  });

  testWidgets('a device id in the route reaches the read', (tester) async {
    await driver.open(
      tester,
      repo: FakeCommandsRepository(
        board: cmdBoard(deviceId: 'd7', lines: [commandLine()]),
      ),
      deviceId: 'd7',
    );

    expect(driver.repository.lastDeviceId, 'd7');
    expect(find.textContaining('one device'), findsOneWidget);
  });
}
