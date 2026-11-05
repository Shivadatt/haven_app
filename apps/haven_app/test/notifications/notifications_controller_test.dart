import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/notifications/controllers/notifications_controller.dart';
import 'package:haven_app/features/notifications/data/alerts_repository.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';

void main() {
  tearDown(Get.reset);

  group('NotificationsController', () {
    test('loads on open and holds what the read gave', () async {
      final FakeAlertsRepository repo = FakeAlertsRepository(
        board: alertBoard(lines: [alertLine()]),
      );
      final NotificationsController controller = NotificationsController(
        repository: repo,
      );
      controller.onInit();
      await pumpEventQueue();

      expect(repo.loadCount, 1);
      expect(controller.isLoading.value, isFalse);
      expect(controller.board.value!.valueOrNull!.lines, hasLength(1));
    });

    test('a refused read is kept as a refusal, not as an empty list', () async {
      final NotificationsController controller = NotificationsController(
        repository: FakeAlertsRepository(),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.failureOrNull, isA<BlockedFailure>());
      expect(controller.isLoading.value, isFalse);
    });

    test('a network failure is not filed as a specification gap', () async {
      final NotificationsController controller = NotificationsController(
        repository: FakeAlertsRepository(
          failWith: const NetworkFailure('Offline.'),
        ),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.failureOrNull, isA<NetworkFailure>());
    });

    test('a read that has not answered leaves the page in its busy state', () {
      final NotificationsController controller = NotificationsController(
        repository: FakeAlertsRepository(),
      );

      expect(controller.isLoading.value, isTrue);
      expect(controller.board.value, isNull);
    });

    test('pull to refresh reads again and replaces what it got', () async {
      final FakeAlertsRepository repo = FakeAlertsRepository(
        board: alertBoard(lines: [alertLine()]),
      );
      final NotificationsController controller = NotificationsController(
        repository: repo,
      );
      controller.onInit();
      await pumpEventQueue();
      repo.board = alertBoard(
        lines: [
          alertLine(),
          alertLine(id: 'a2'),
        ],
      );
      await controller.reload();

      expect(repo.loadCount, 2);
      expect(controller.board.value!.valueOrNull!.lines, hasLength(2));
    });

    test('the device is not registered, and the seam says so', () async {
      final NotificationsController controller = NotificationsController(
        repository: FakeAlertsRepository(board: alertBoard()),
      );

      // No delivery was injected, so the build's only implementation answers.
      expect(controller.deviceIsRegistered, isFalse);
    });

    test(
      'a delivery that claims a registration is what the screen shows',
      () async {
        final NotificationsController controller = NotificationsController(
          repository: FakeAlertsRepository(board: alertBoard()),
          delivery: RegisteredDelivery(),
        );

        expect(controller.deviceIsRegistered, isTrue);
      },
    );

    test('the permission question opens the screen that owns it', () async {
      final List<(String, String, Object?)> moved = [];
      final NotificationsController controller = NotificationsController(
        repository: FakeAlertsRepository(),
        push: (String route, Object? arg) => moved.add(('push', route, arg)),
      );

      controller.goToSettings();

      // It asks the settings screen rather than the operating system twice.
      expect(moved, [('push', AppRoutes.settings, null)]);
    });

    test('no family replaces the stack with setup', () async {
      final List<(String, String, Object?)> moved = [];
      final NotificationsController controller = NotificationsController(
        repository: FakeAlertsRepository(noFamily: true),
        replace: (String route, Object? arg) =>
            moved.add(('replace', route, arg)),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.valueOrNull, isNull);
      controller.goToSetup();
      expect(moved, [('replace', AppRoutes.onboarding, null)]);
    });

    test('the board carries the refusals the page renders', () async {
      final NotificationsController controller = NotificationsController(
        repository: FakeAlertsRepository(board: alertBoard()),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(
        controller.board.value!.valueOrNull!.ackGap.missing,
        HavenAlertsRepository.ackMissing,
      );
      expect(
        controller.board.value!.valueOrNull!.deliveryGap,
        same(HavenAlertsRepository.deliveryGap),
      );
    });
  });
}
