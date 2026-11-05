import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/core/errors/captured_gaps.dart';
import 'package:haven_app/features/location/controllers/location_controller.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';

void main() {
  group('LocationController', () {
    test('loads on open and holds what the read gave', () async {
      final FakeLocationRepository repo = FakeLocationRepository(
        board: board(lines: [fixLine()]),
      );
      final LocationController controller = LocationController(
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
      'a refused read is kept as a refusal, not shown as no places',
      () async {
        final LocationController controller = LocationController(
          repository: FakeLocationRepository(),
        );
        controller.onInit();
        await pumpEventQueue();

        expect(controller.board.value!.failureOrNull, isA<BlockedFailure>());
        expect(controller.isLoading.value, isFalse);
      },
    );

    test('a device id from the route narrows every read it makes', () async {
      final FakeLocationRepository repo = FakeLocationRepository(
        board: board(deviceId: 'd1'),
      );
      final LocationController controller = LocationController(
        repository: repo,
        deviceId: 'd1',
      );
      controller.onInit();
      await pumpEventQueue();
      await controller.reload();

      expect(repo.lastDeviceId, 'd1');
      expect(repo.loadCount, 2);
    });

    test('coordinates start hidden and stay hidden across a refresh', () async {
      final FakeLocationRepository repo = FakeLocationRepository(
        board: board(lines: [fixLine()]),
      );
      final LocationController controller = LocationController(
        repository: repo,
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.showsCoordinates.value, isFalse);
      controller.toggleCoordinates();
      expect(controller.showsCoordinates.value, isTrue);
      await controller.reload();
      expect(controller.showsCoordinates.value, isTrue);
    });

    test('the presence gap reaches the page through the board', () async {
      final LocationController controller = LocationController(
        repository: FakeLocationRepository(board: board(lines: [fixLine()])),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(
        controller.board.value!.valueOrNull!.presenceGap.missing,
        CapturedGaps.presenceLaneMissing,
      );
    });

    test('a network failure is not filed as a specification gap', () async {
      final LocationController controller = LocationController(
        repository: FakeLocationRepository(
          failWith: const NetworkFailure('Offline.'),
        ),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.failureOrNull, isA<NetworkFailure>());
    });

    test('a read that has not answered leaves the page in its busy state', () {
      final LocationController controller = LocationController(
        repository: FakeLocationRepository(),
      );
      expect(controller.isLoading.value, isTrue);
      expect(controller.board.value, isNull);
    });

    test('no family replaces the stack with setup', () async {
      final List<(String, String, Object?)> moved = [];
      final LocationController controller = LocationController(
        repository: FakeLocationRepository(noFamily: true),
        replace: (String route, Object? arg) =>
            moved.add(('replace', route, arg)),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.valueOrNull, isNull);
      controller.goToSetup();
      expect(moved, [('replace', AppRoutes.onboarding, null)]);
    });

    test('the read answers even when no device has reported a place', () async {
      final LocationController controller = LocationController(
        repository: FakeLocationRepository(board: board()),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.isOk, isTrue);
      expect(controller.board.value!.valueOrNull!.hasLines, isFalse);
    });
  });
}
