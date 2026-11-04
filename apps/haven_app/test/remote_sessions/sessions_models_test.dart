import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/remote_sessions/data/sessions_models.dart';
import 'package:haven_models/haven_models.dart';

import 'fakes.dart';

/// The lifecycle columns are optional, so a line with a history is built
/// directly rather than through the short fixture.
SessionLine lived({
  String status = 'ended',
  bool consentRecorded = true,
  String? endedBy = 'u1',
  String? endedReason,
}) => SessionLine(
  RemoteSession(
    id: 's1',
    familyId: 'f1',
    deviceId: 'd1',
    parentUserId: 'u1',
    childUserId: 'u2',
    kind: 'video',
    status: status,
    requestedAt: DateTime.parse('2026-11-01T09:00:00.000Z'),
    acceptedAt: DateTime.parse('2026-11-01T09:00:30.000Z'),
    startedAt: DateTime.parse('2026-11-01T09:01:00.000Z'),
    endedAt: DateTime.parse('2026-11-01T09:05:00.000Z'),
    consentRecorded: consentRecorded,
    endedBy: endedBy,
    endedReason: endedReason,
    createdAt: DateTime.parse('2026-11-01T09:00:00.000Z'),
  ),
);

void main() {
  group('SessionLine says what the row says', () {
    test('a kind outside the CHECK is echoed, not sorted', () {
      expect(sessionLine(kind: 'video').what, 'A request for a video session');
      expect(sessionLine(kind: 'audio').what, 'A request for an audio session');
      expect(
        sessionLine(kind: 'screen_share').what,
        'A session this build cannot classify (screen_share)',
      );
    });

    test('a status outside the CHECK reads as unrecognised', () {
      expect(sessionLine(status: 'nope').statusLabel, 'Unrecognised');
      expect(
        sessionLine(status: 'nope').state,
        'A state this build does not recognise (nope)',
      );
    });

    test('an active row is the record saying a word, not a connection', () {
      expect(
        sessionLine(status: 'active').state,
        'The record says it is running. Nothing here carries sound or picture.',
      );
      expect(sessionLine(status: 'active').statusLabel, 'Running');
    });

    test('consent is a mark on the row and nothing more', () {
      expect(
        sessionLine(consentRecorded: true).consent,
        'Consent is recorded as given on this row',
      );
      expect(
        sessionLine(consentRecorded: false).consent,
        'Nothing on this row records consent',
      );
    });

    test('an open row with no consent is a live row without consent', () {
      expect(
        sessionLine(
          status: 'active',
          consentRecorded: false,
        ).liveWithoutConsent,
        isTrue,
      );
      expect(
        sessionLine(status: 'active', consentRecorded: true).liveWithoutConsent,
        isFalse,
      );
      // An ended row is not "open without consent" even without the mark.
      expect(
        sessionLine(status: 'ended', consentRecorded: false).liveWithoutConsent,
        isFalse,
      );
    });

    test('the trail holds only the columns that were filled', () {
      final String trail = lived(endedReason: 'the child tapped end').trail;

      expect(trail, contains('requested 2026-11-01T09:00:00.000Z'));
      expect(trail, contains('accepted 2026-11-01T09:00:30.000Z'));
      expect(trail, contains('started 2026-11-01T09:01:00.000Z'));
      expect(trail, contains('ended 2026-11-01T09:05:00.000Z'));
      expect(trail, contains('the record names who ended it'));
      expect(trail, isNot(contains('null')));
      // `ended_by` is a bare user id and the profile lane cannot name it.
      expect(trail, isNot(contains('u1')));
    });

    test('a free-text reason arrives as it was written', () {
      expect(lived(endedReason: 'the child tapped end').whyClosed, isNotNull);
      expect(lived(endedBy: null).whoClosed, isNull);
    });

    test('a pending row says how long it waits', () {
      // `remote_sessions_pending_expiry_check` (sql:482) makes a `requested` row
      // carry `expires_at`, so the line has something to report.
      final SessionLine pending = SessionLine(
        RemoteSession(
          id: 's1',
          familyId: 'f1',
          deviceId: 'd1',
          parentUserId: 'u1',
          childUserId: 'u2',
          kind: 'video',
          status: 'requested',
          requestedAt: DateTime.parse('2026-11-01T09:00:00.000Z'),
          expiresAt: DateTime.parse('2026-11-01T09:10:00.000Z'),
          consentRecorded: false,
          createdAt: DateTime.parse('2026-11-01T09:00:00.000Z'),
        ),
      );

      expect(pending.until, 'waits until 2026-11-01T09:10:00.000Z');
      expect(pending.opened, isNull);
      expect(lived().until, isNull);
    });

    test('an unnamed device stays unnamed in words the screen can show', () {
      expect(sessionLine().whose, 'a device this build cannot name');
      expect(sessionLine(deviceName: 'Ivy').whose, 'Ivy');
    });
  });

  group('SessionBoard counts what was read', () {
    test('the count names the window, not a history', () {
      expect(
        sessionBoard(lines: [sessionLine()]).counted,
        '1 session record read — the newest ${SessionBoard.window} the backend '
        'would give for this family.',
      );
      expect(
        sessionBoard(lines: [sessionLine(), sessionLine()]).counted,
        startsWith('2 session records read'),
      );
    });

    test('open rows are named', () {
      final SessionBoard board = sessionBoard(
        lines: [
          sessionLine(status: 'active'),
          sessionLine(id: 's2', status: 'ended'),
        ],
      );

      expect(board.liveCount, 1);
      expect(board.liveLine, '1 of 2 are still open in the record.');
    });

    test('a live row without consent is called out', () {
      final SessionBoard board = sessionBoard(
        lines: [sessionLine(status: 'active', consentRecorded: false)],
      );

      expect(board.unconsentedLiveCount, 1);
      expect(
        board.consentLine,
        allOf(
          contains('1 open row carries no consent mark'),
          contains('not a session Haven would connect to'),
        ),
      );
    });

    test('a list of consented rows says so', () {
      expect(
        sessionBoard(lines: [sessionLine(status: 'active')]).consentLine,
        'Every open row in this list carries a consent mark.',
      );
    });

    test('an empty list is not an error', () {
      final SessionBoard board = sessionBoard();

      expect(board.hasLines, isFalse);
      expect(board.lines, isEmpty);
    });
  });
}
