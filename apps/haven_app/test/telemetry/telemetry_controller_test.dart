import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/telemetry/controllers/telemetry_controller.dart';
import 'package:haven_app/features/telemetry/data/telemetry_models.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';

void main() {
  group('TelemetryController', () {
    test('loads on open and holds what the read gave', () async {
      final FakeTelemetryRepository repo = FakeTelemetryRepository(
        board: trailBoard(lines: [auditLine()]),
      );
      final TelemetryController controller = TelemetryController(
        repository: repo,
      );
      controller.onInit();
      await pumpEventQueue();

      expect(repo.loadCount, 1);
      expect(repo.lastDeviceId, isNull);
      expect(controller.isLoading.value, isFalse);
      expect(controller.board.value!.valueOrNull!.lines, hasLength(1));
    });

    test('a device id scopes every read the card makes', () async {
      final FakeTelemetryRepository repo = FakeTelemetryRepository(
        board: trailBoard(deviceId: 'd1', lines: [auditLine()]),
      );
      final TelemetryController controller = TelemetryController(
        repository: repo,
        deviceId: 'd1',
      );
      controller.onInit();
      await pumpEventQueue();
      await controller.reload();

      expect(repo.lastDeviceId, 'd1');
      expect(repo.loadCount, 2);
    });

    test('a refused read stays a refusal instead of an empty trail', () async {
      final TelemetryController controller = TelemetryController(
        repository: FakeTelemetryRepository(),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.failureOrNull, isA<BlockedFailure>());
    });

    test('a read that has not answered leaves the card in its busy state', () {
      final TelemetryController controller = TelemetryController(
        repository: FakeTelemetryRepository(),
      );
      expect(controller.isLoading.value, isTrue);
      expect(controller.board.value, isNull);
    });

    test('a network failure is not filed as a specification gap', () async {
      final TelemetryController controller = TelemetryController(
        repository: FakeTelemetryRepository(
          failWith: const NetworkFailure('Offline.'),
        ),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.failureOrNull, isA<NetworkFailure>());
    });

    test('an empty trail is an answer, not a failure', () async {
      final TelemetryController controller = TelemetryController(
        repository: FakeTelemetryRepository(board: trailBoard()),
      );
      controller.onInit();
      await pumpEventQueue();

      final TelemetryBoard board = controller.board.value!.valueOrNull!;
      expect(board.hasLines, isFalse);
      expect(board.counted, startsWith('0 entries read'));
    });
  });
}
