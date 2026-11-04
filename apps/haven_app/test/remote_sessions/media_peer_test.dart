import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/remote_sessions/data/session_gaps.dart';
import 'package:haven_app/features/remote_sessions/services/media_peer.dart';
import 'package:haven_core/haven_core.dart';

void main() {
  group('UnspecifiedMediaPeer', () {
    test(
      'refuses to open a path, citing the absence the screens show',
      () async {
        final Result<void> started = await const UnspecifiedMediaPeer().start(
          's1',
        );

        final HavenFailure? why = started.failureOrNull;
        expect(why, isA<BlockedFailure>());
        expect(why!.detail, startsWith('BLOCKED — SPECIFICATION REQUIRED:'));
        // The sentence a parent reads on the session screen and the sentence the
        // peer returns are the same sentence, from the same constant.
        expect((why as BlockedFailure).missing, SessionGaps.mediaMissing);
      },
    );

    test(
      'refuses to take a connection down, because none was ever up',
      () async {
        final Result<void> stopped = await const UnspecifiedMediaPeer().stop();

        expect(stopped.failureOrNull, isA<BlockedFailure>());
        expect(
          (stopped.failureOrNull! as BlockedFailure).message,
          'Haven cannot take a session connection down in this build yet.',
        );
      },
    );

    test('never reports media flowing, whatever was asked of it', () async {
      const UnspecifiedMediaPeer peer = UnspecifiedMediaPeer();
      await peer.start('s1');
      await peer.stop();

      expect(peer.isCarrying, isFalse);
    });

    test('the refusal does not depend on what it is asked for', () async {
      // It refuses an unreadable session exactly as loudly as a readable one: a
      // missing media spec is not a per-row question.
      for (final String id in ['', 's1', 'not-a-session']) {
        expect(
          await const UnspecifiedMediaPeer().start(id),
          isA<Err<void>>(),
          reason: 'refusing $id',
        );
      }
    });
  });
}
