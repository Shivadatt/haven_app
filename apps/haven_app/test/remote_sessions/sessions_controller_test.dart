import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/app/routes/app_routes.dart';
import 'package:haven_app/features/remote_sessions/controllers/sessions_controller.dart';
import 'package:haven_app/features/remote_sessions/data/session_gaps.dart';
import 'package:haven_core/haven_core.dart';

import '../support/feed_fakes.dart';
import 'fakes.dart';

void main() {
  tearDown(Get.reset);

  group('SessionsController', () {
    test('loads on open and holds what the read gave', () async {
      final FakeSessionsRepository repo = FakeSessionsRepository(
        board: sessionBoard(lines: [sessionLine()]),
      );
      final SessionsController controller = SessionsController(
        repository: repo,
      );
      controller.onInit();
      await pumpEventQueue();

      expect(repo.loadCount, 1);
      expect(controller.isLoading.value, isFalse);
      expect(controller.board.value!.valueOrNull!.lines, hasLength(1));
    });

    test('a refused read is kept as a refusal, not as an empty list', () async {
      final SessionsController controller = SessionsController(
        repository: FakeSessionsRepository(),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.failureOrNull, isA<BlockedFailure>());
      expect(controller.isLoading.value, isFalse);
    });

    test('a network failure is not filed as a specification gap', () async {
      final SessionsController controller = SessionsController(
        repository: FakeSessionsRepository(
          failWith: const NetworkFailure('Offline.'),
        ),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.board.value!.failureOrNull, isA<NetworkFailure>());
    });

    test('a read that has not answered leaves the page in its busy state', () {
      final SessionsController controller = SessionsController(
        repository: FakeSessionsRepository(),
      );

      expect(controller.isLoading.value, isTrue);
      expect(controller.board.value, isNull);
    });

    test('pull to refresh reads again and replaces what it got', () async {
      final FakeSessionsRepository repo = FakeSessionsRepository(
        board: sessionBoard(lines: [sessionLine()]),
      );
      final SessionsController controller = SessionsController(
        repository: repo,
      );
      controller.onInit();
      await pumpEventQueue();
      repo.board = sessionBoard(lines: [sessionLine(), sessionLine()]);
      await controller.refresh();

      expect(repo.loadCount, 2);
      expect(controller.board.value!.valueOrNull!.lines, hasLength(2));
    });

    test(
      'the session table is watched, and a hint is a reason to read',
      () async {
        final FakeChangeFeed feed = FakeChangeFeed();
        final FakeSessionsRepository repo = FakeSessionsRepository(
          board: sessionBoard(),
        );
        final SessionsController controller = SessionsController(
          repository: repo,
          feed: () => feed,
        );
        controller.onInit();
        await pumpEventQueue();

        expect(feed.watchedTables, [TableName.remoteSessions]);
        expect(repo.loadCount, 1);

        // A feed event is a hint, never a row: the controller must go back to the
        // repository rather than treat the payload as data.
        feed.emit(TableName.remoteSessions, {'id': 's1', 'status': 'active'});
        await pumpEventQueue();
        expect(repo.loadCount, 2);
        expect(controller.board.value!.valueOrNull!.lines, isEmpty);
      },
    );

    test(
      'closing the screen stops the hint without closing the shared lane',
      () async {
        final FakeChangeFeed feed = FakeChangeFeed();
        final FakeSessionsRepository repo = FakeSessionsRepository(
          board: sessionBoard(),
        );
        // Get.put runs onInit through the lifecycle, and Get.delete runs onClose.
        Get.put<SessionsController>(
          SessionsController(repository: repo, feed: () => feed),
        );
        await pumpEventQueue();
        expect(repo.loadCount, 1);

        Get.delete<SessionsController>();
        await pumpEventQueue();
        feed.emit(TableName.remoteSessions);
        await pumpEventQueue();

        // The feed is one object shared with every other open screen, so this
        // controller releases only its own subscription.
        expect(repo.loadCount, 1);
        expect(feed.disposeCount, 0);
      },
    );

    test(
      'opening a record pushes the detail route with the id it was given',
      () async {
        final List<(String, String, Object?)> moved = [];
        final SessionsController controller = SessionsController(
          repository: FakeSessionsRepository(),
          push: (String route, Object? arg) => moved.add(('push', route, arg)),
        );

        controller.openDetail('s7');

        expect(moved, [('push', AppRoutes.remoteSessionDetail, 's7')]);
      },
    );

    test('no family replaces the stack with setup', () async {
      final List<(String, String, Object?)> moved = [];
      final SessionsController controller = SessionsController(
        repository: FakeSessionsRepository(noFamily: true),
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
      final SessionsController controller = SessionsController(
        repository: FakeSessionsRepository(board: sessionBoard()),
      );
      controller.onInit();
      await pumpEventQueue();

      expect(
        controller.board.value!.valueOrNull!.startGap.missing,
        SessionGaps.startMissing,
      );
      expect(
        controller.board.value!.valueOrNull!.mediaGap,
        same(SessionGaps.mediaGap),
      );
    });
  });
}
