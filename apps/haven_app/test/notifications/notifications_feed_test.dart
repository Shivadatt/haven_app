import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/notifications/controllers/notifications_controller.dart';

import '../support/feed_fakes.dart';
import 'fakes.dart';

/// The Realtime hint lane, held apart from the read tests because it is a
/// different promise: an event says "read this again" and never becomes a row
/// (`docs/stage1/02-architecture.md:23`).
void main() {
  tearDown(Get.reset);

  group('NotificationsController watching the reports table', () {
    test('a hint is a reason to read, not data to show', () async {
      final FakeChangeFeed feed = FakeChangeFeed();
      final FakeAlertsRepository repo = FakeAlertsRepository(
        board: alertBoard(),
      );
      final NotificationsController controller = NotificationsController(
        repository: repo,
        feed: () => feed,
      );
      controller.onInit();
      await pumpEventQueue();

      expect(feed.watchedTables, [TableName.safetyAlerts]);
      expect(repo.loadCount, 1);

      feed.emit(TableName.safetyAlerts, {'id': 'a9', 'message': 'fabricated'});
      await pumpEventQueue();

      expect(repo.loadCount, 2);
      // The screen still shows what the read gave, not what the hint carried.
      expect(controller.board.value!.valueOrNull!.lines, isEmpty);
    });

    test('a dropped channel is a stale screen, not a broken one', () async {
      final FakeChangeFeed feed = FakeChangeFeed();
      final FakeAlertsRepository repo = FakeAlertsRepository(
        board: alertBoard(lines: [alertLine()]),
      );
      final NotificationsController controller = NotificationsController(
        repository: repo,
        feed: () => feed,
      );
      controller.onInit();
      await pumpEventQueue();
      feed.dispose();

      // Nothing retries the socket, and the read that already happened stands.
      expect(controller.board.value!.valueOrNull!.lines, hasLength(1));
      expect(repo.loadCount, 1);
    });

    test(
      'closing the screen stops the hint without closing the shared lane',
      () async {
        final FakeChangeFeed feed = FakeChangeFeed();
        final FakeAlertsRepository repo = FakeAlertsRepository(
          board: alertBoard(),
        );
        // Get.put runs onInit through the lifecycle; Get.delete runs onClose.
        Get.put<NotificationsController>(
          NotificationsController(repository: repo, feed: () => feed),
        );
        await pumpEventQueue();
        expect(repo.loadCount, 1);

        Get.delete<NotificationsController>();
        await pumpEventQueue();
        feed.emit(TableName.safetyAlerts);
        await pumpEventQueue();

        // The feed is one object shared with every other open screen, so this
        // controller releases only its own subscription.
        expect(repo.loadCount, 1);
        expect(feed.disposeCount, 0);
      },
    );
  });
}
