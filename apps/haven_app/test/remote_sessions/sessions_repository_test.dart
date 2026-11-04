import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/remote_sessions/data/session_gaps.dart';
import 'package:haven_app/features/remote_sessions/data/sessions_models.dart';
import 'package:haven_core/haven_core.dart';

import '../child_devices/fakes.dart';
import '../support/data_fakes.dart';
import 'fakes.dart';
import 'harness.dart';

void main() {
  group('HavenSessionsRepository.load', () {
    test('reads this family\'s sessions and nothing else', () async {
      final Harness harness = Harness(
        tables: sessionTables(
          sessions: [
            sessionRow('s1'),
            sessionRow('s2', kind: 'audio'),
          ],
        ),
      );

      final SessionBoard board = await harness.okBoard();

      expect(board.familyId, 'f1');
      expect(board.lines, hasLength(2));
      expect(harness.rows.lastTable, TableName.remoteSessions);
      // The family id comes from the caller's own membership row, never from a
      // value the route could have been handed.
      expect(harness.rows.filters.first, {'user_id': 'u1'});
      expect(harness.rows.filters.last, {'family_id': 'f1'});
      expect(harness.rows.orderings.last, 'requested_at');
      expect(harness.rows.limits.last, SessionBoard.window);
    });

    test(
      'an unreadable session table is a failure, not an empty list',
      () async {
        final Harness harness = Harness(
          withRows: FakeRowReader(sessionTables(), {
            TableName.remoteSessions: const BackendFailure(
              'fake: rows unreadable',
            ),
          }),
        );

        final Result<SessionBoard?> read = await harness.subject.load();

        expect(read.failureOrNull, isA<BackendFailure>());
      },
    );

    test(
      'an account with no family reads no board rather than an empty one',
      () async {
        final Result<SessionBoard?> read = await Harness.withoutFamily().subject
            .load();

        expect(read.valueOrNull, isNull);
      },
    );

    test(
      'the addressee stays unnamed and the refusal travels with the rows',
      () async {
        final SessionBoard board = await Harness(
          tables: sessionTables(sessions: [sessionRow('s1')]),
        ).okBoard();

        expect(board.lines.single.whose, 'a device this build cannot name');
        expect(board.deviceGap, isA<BlockedFailure>());
      },
    );

    test('a readable device lane puts names back on the rows', () async {
      final SessionBoard board = await Harness(
        tables: sessionTables(sessions: [sessionRow('s1')]),
        withDevices: FakeDevicesRepository(
          devices: [device('d1', name: 'Ivy')],
        ),
      ).okBoard();

      expect(board.lines.single.whose, 'Ivy');
      expect(board.deviceGap, isNull);
    });

    test('a session of another family is never reached', () async {
      // The filter carries the caller's own family id, so a row that belongs to
      // someone else cannot answer even if an id is guessed.
      final Harness harness = Harness(
        tables: sessionTables(sessions: [sessionRow('s1')]),
      );
      final SessionBoard board = await harness.okBoard();

      expect(board.lines.single.session.familyId, 'f1');
      expect(harness.rows.filters.last.containsKey('family_id'), isTrue);
    });
  });

  group('the two refusals the session list carries', () {
    test('asking for a session is refused, citing both closed lanes', () async {
      final SessionBoard board = await Harness(
        tables: sessionTables(sessions: [sessionRow('s1')]),
      ).okBoard();

      expect(
        board.startGap.message,
        'Haven cannot ask for, answer or retire a session in this build yet.',
      );
      expect(board.startGap.missing, contains('request_remote_session'));
      expect(board.startGap.missing, contains('expire_stale_sessions'));
      expect(board.startGap.missing, contains('04-rls-matrix.md:139-141'));
      expect(
        board.startGap.detail,
        startsWith('BLOCKED — SPECIFICATION REQUIRED:'),
      );
    });

    test(
      'the media path is refused, citing the absence rather than a limit',
      () async {
        final SessionBoard board = await Harness(
          tables: sessionTables(sessions: [sessionRow('s1')]),
        ).okBoard();

        expect(board.mediaGap.missing, contains('TURN'));
        expect(board.mediaGap.missing, contains('00-status-register.md X2'));
        expect(board.mediaGap, same(SessionGaps.mediaGap));
      },
    );
  });
}
