import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/device_commands/controllers/commands_controller.dart';
import 'package:haven_app/features/device_commands/data/commands_repository.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';

void main() {
  group('CommandsController', () {
    test('loads on open and holds what the read gave', () async {
      final FakeCommandsRepository repo = FakeCommandsRepository(
        board: cmdBoard(lines: [commandLine()]),
      );
      final CommandsController controller = CommandsController(
        repository: repo,
      );
      controller.onInit();
      await pumpEventQueue();

      expect(repo.loadCount, 1);
      expect(repo.lastDeviceId, isNull);
      expect(controller.isLoading.value, isFalse);
      expect(controller.board.value!.valueOrNull!.lines, hasLength(1));
    });

    test(
      'a refused read is kept as a refusal, not shown as an empty log',
      () async {
        final CommandsController controller = CommandsController(
          repository: FakeCommandsRepository(),
        );
        controller.onInit();
        await pumpEventQueue();

        expect(controller.board.value!.failureOrNull, isA<BlockedFailure>());
        expect(controller.isLoading.value, isFalse);
      },
    );

    test('a device id from the route narrows every read it makes', () async {
      final FakeCommandsRepository repo = FakeCommandsRepository(
        board: cmdBoard(deviceId: 'd1'),
      );
      final CommandsController controller = CommandsController(
        repository: repo,
        deviceId: 'd1',
      );
      controller.onInit();
      await pumpEventQueue();
      await controller.reload();

      expect(repo.lastDeviceId, 'd1');
      expect(repo.loadCount, 2);
    });

    test('the write refusal reaches the page through the board', () async {
      final CommandsController controller = CommandsController(
        repository: FakeCommandsRepository(
          board: cmdBoard(lines: [commandLine()]),
        ),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(
        controller.board.value!.valueOrNull!.writeGap.missing,
        HavenCommandsRepository.writeMissing,
      );
    });

    test('a network failure is not filed as a specification gap', () async {
      final CommandsController controller = CommandsController(
        repository: FakeCommandsRepository(
          failWith: const NetworkFailure('Offline.'),
        ),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.failureOrNull, isA<NetworkFailure>());
    });

    test('a read that has not answered leaves the page in its busy state', () {
      final CommandsController controller = CommandsController(
        repository: FakeCommandsRepository(),
      );
      expect(controller.isLoading.value, isTrue);
      expect(controller.board.value, isNull);
    });

    test('no family replaces the stack with setup', () async {
      final List<(String, String, Object?)> moved = [];
      final CommandsController controller = CommandsController(
        repository: FakeCommandsRepository(noFamily: true),
        replace: (String route, Object? arg) =>
            moved.add(('replace', route, arg)),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.valueOrNull, isNull);
      controller.goToSetup();
      expect(moved, [('replace', AppRoutes.onboarding, null)]);
    });

    test(
      'the read answers even when no instruction was ever written',
      () async {
        final CommandsController controller = CommandsController(
          repository: FakeCommandsRepository(board: cmdBoard()),
        );
        controller.onInit();
        await pumpEventQueue();

        expect(controller.board.value!.isOk, isTrue);
        expect(controller.board.value!.valueOrNull!.hasLines, isFalse);
      },
    );
  });
}
