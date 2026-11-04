import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/core/errors/captured_gaps.dart';
import 'package:haven_app/features/device_activity/controllers/activity_controller.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';

void main() {
  group('ActivityController', () {
    test('loads on open and holds what the read gave', () async {
      final FakeActivityRepository repo = FakeActivityRepository(
        board: board(lines: [line()]),
      );
      final ActivityController controller = ActivityController(
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
      'a refused read is kept as a refusal, not shown as an empty list',
      () async {
        final ActivityController controller = ActivityController(
          repository: FakeActivityRepository(),
        );
        controller.onInit();
        await pumpEventQueue();

        final HavenFailure? failure = controller.board.value!.failureOrNull;
        expect(failure, isA<BlockedFailure>());
        expect(controller.isLoading.value, isFalse);
      },
    );

    test(
      'the device gap reaches the page through the board, not a copy',
      () async {
        final BlockedFailure gap =
            CapturedGaps.deviceLaneUnavailable<void>().failureOrNull
                as BlockedFailure;
        final ActivityController controller = ActivityController(
          repository: FakeActivityRepository(board: board(deviceGap: gap)),
        );
        controller.onInit();
        await pumpEventQueue();

        expect(
          controller.board.value!.valueOrNull!.deviceGap!.missing,
          CapturedGaps.deviceLaneMissing,
        );
      },
    );

    test('a device id from the route narrows every read it makes', () async {
      final FakeActivityRepository repo = FakeActivityRepository(
        board: board(deviceId: 'd1'),
      );
      final ActivityController controller = ActivityController(
        repository: repo,
        deviceId: 'd1',
      );
      controller.onInit();
      await pumpEventQueue();
      await controller.refresh();

      expect(repo.lastDeviceId, 'd1');
      expect(repo.loadCount, 2);
    });

    test(
      'an empty device id reads the family, not a device with no id',
      () async {
        final FakeActivityRepository repo = FakeActivityRepository(
          board: board(),
        );
        final ActivityController controller = ActivityController(
          repository: repo,
          deviceId: '',
        );
        controller.onInit();
        await pumpEventQueue();

        expect(repo.lastDeviceId, isNull);
      },
    );

    test('a network failure is not filed as a specification gap', () async {
      final ActivityController controller = ActivityController(
        repository: FakeActivityRepository(
          failWith: const NetworkFailure('Offline.'),
        ),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.failureOrNull, isA<NetworkFailure>());
    });

    test(
      'refresh re-reads without the busy flag that hides the page',
      () async {
        final FakeActivityRepository repo = FakeActivityRepository(
          board: board(lines: [line()]),
        );
        final ActivityController controller = ActivityController(
          repository: repo,
        );
        controller.onInit();
        await pumpEventQueue();
        expect(controller.isLoading.value, isFalse);

        await controller.refresh();
        expect(repo.loadCount, 2);
        expect(controller.isLoading.value, isFalse);
      },
    );

    test('load sets the busy flag while the read is outstanding', () async {
      final ActivityController controller = ActivityController(
        repository: FakeActivityRepository(),
      );
      expect(controller.isLoading.value, isTrue);
      expect(controller.board.value, isNull);
    });

    test('no family replaces the stack with setup', () async {
      final List<(String, String, Object?)> moved = [];
      final ActivityController controller = ActivityController(
        repository: FakeActivityRepository(noFamily: true),
        replace: (String route, Object? arg) =>
            moved.add(('replace', route, arg)),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.valueOrNull, isNull);
      controller.goToSetup();
      expect(moved, [('replace', AppRoutes.onboarding, null)]);
    });

    test('the read answers even when the family has no rows yet', () async {
      final ActivityController controller = ActivityController(
        repository: FakeActivityRepository(board: board()),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.isOk, isTrue);
      expect(controller.board.value!.valueOrNull!.hasLines, isFalse);
    });
  });
}
