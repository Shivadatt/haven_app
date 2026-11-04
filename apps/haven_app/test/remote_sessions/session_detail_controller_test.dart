import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/remote_sessions/controllers/session_detail_controller.dart';
import 'package:haven_app/features/remote_sessions/data/session_detail_models.dart';
import 'package:haven_app/features/remote_sessions/data/session_gaps.dart';
import 'package:haven_app/features/remote_sessions/services/media_peer.dart';
import 'package:haven_core/haven_core.dart';

import '../support/feed_fakes.dart';
import 'fakes.dart';

/// A peer that says it is carrying, which nothing in this build can.
///
/// It exists so the one assertion that matters is testable: the screen shows what
/// the peer answers rather than what a session row claims.
class ClaimingPeer implements SessionMediaPeer {
  bool carrying = true;

  @override
  Future<Result<void>> start(String sessionId) async => okVoid();

  @override
  Future<Result<void>> stop() async => okVoid();

  @override
  bool get isCarrying => carrying;
}

void main() {
  tearDown(Get.reset);

  group('SessionDetailController', () {
    test('reads the record the route named', () async {
      final FakeSessionsRepository repo = FakeSessionsRepository(
        details: {'s1': sessionDetail()},
      );
      final SessionDetailController controller = SessionDetailController(
        repository: repo,
        sessionId: 's1',
      );
      controller.onInit();
      await pumpEventQueue();

      expect(repo.lastSessionId, 's1');
      expect(controller.detail.value!.valueOrNull!.line.session.id, 's1');
      expect(controller.isLoading.value, isFalse);
    });

    test('a route with no id names nothing and reads nothing', () async {
      final FakeSessionsRepository repo = FakeSessionsRepository(
        details: {'s1': sessionDetail()},
      );
      final SessionDetailController controller = SessionDetailController(
        repository: repo,
        sessionId: '',
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.detail.value!.failureOrNull, isA<ValidationFailure>());
      expect(
        controller.detail.value!.failureOrNull!.message,
        'No session was named.',
      );
      expect(repo.detailCount, 0);
      expect(controller.isLoading.value, isFalse);
    });

    test('an unreadable record stays a failure the page can retry', () async {
      final SessionDetailController controller = SessionDetailController(
        repository: FakeSessionsRepository(),
        sessionId: 's1',
      );
      controller.onInit();
      await pumpEventQueue();

      expect(controller.detail.value!.failureOrNull, isA<BlockedFailure>());
    });

    test('the buffer is watched for this session alone', () async {
      final FakeChangeFeed feed = FakeChangeFeed();
      final FakeSessionsRepository repo = FakeSessionsRepository(
        details: {'s1': sessionDetail()},
      );
      final SessionDetailController controller = SessionDetailController(
        repository: repo,
        sessionId: 's1',
        feed: () => feed,
      );
      controller.onInit();
      await pumpEventQueue();

      expect(feed.watchedTables, [TableName.webrtcSignals]);
      // The hint is filtered by the session this screen is about, not by every
      // session the family has.
      expect(feed.filters.single, {'session_id': 's1'});

      feed.emit(TableName.webrtcSignals, {'id': 'g1'});
      await pumpEventQueue();

      expect(repo.detailCount, 2);
      expect(controller.detail.value!.valueOrNull!.signals, isEmpty);
    });

    test('closing the record releases the hint, not the lane', () async {
      final FakeChangeFeed feed = FakeChangeFeed();
      final FakeSessionsRepository repo = FakeSessionsRepository(
        details: {'s1': sessionDetail()},
      );
      Get.put<SessionDetailController>(
        SessionDetailController(
          repository: repo,
          sessionId: 's1',
          feed: () => feed,
        ),
      );
      await pumpEventQueue();

      Get.delete<SessionDetailController>();
      feed.emit(TableName.webrtcSignals);
      await pumpEventQueue();

      expect(repo.detailCount, 1);
      expect(feed.disposeCount, 0);
    });

    test('the screen reports the peer, never the row', () async {
      final SessionDetailController quiet = SessionDetailController(
        repository: FakeSessionsRepository(
          details: {'s1': sessionDetail(record: sessionLine(status: 'active'))},
        ),
        sessionId: 's1',
      );
      // No peer was injected, so the build's only implementation answers — and it
      // says nothing is carried even though the row reads "running".
      expect(quiet.carriesMedia, isFalse);
      expect(quiet.detail.value, isNull);

      final SessionDetailController claiming = SessionDetailController(
        repository: FakeSessionsRepository(details: {'s1': sessionDetail()}),
        sessionId: 's1',
        peer: ClaimingPeer(),
      );
      expect(claiming.carriesMedia, isTrue);
    });

    test('the refusals reach the card without paraphrase', () async {
      final SessionDetailController controller = SessionDetailController(
        repository: FakeSessionsRepository(details: {'s1': sessionDetail()}),
        sessionId: 's1',
      );
      controller.onInit();
      await pumpEventQueue();

      final SessionDetail detail = controller.detail.value!.valueOrNull!;
      expect(detail.signalGap, same(SessionGaps.signalGap));
      expect(detail.mediaGap, same(SessionGaps.mediaGap));
    });
  });
}
