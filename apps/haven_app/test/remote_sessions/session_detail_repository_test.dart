import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/remote_sessions/data/session_detail_models.dart';
import 'package:haven_app/features/remote_sessions/data/session_gaps.dart';
import 'package:haven_core/haven_core.dart';

import '../child_devices/fakes.dart';
import '../support/data_fakes.dart';
import 'fakes.dart';
import 'harness.dart';

void main() {
  group('HavenSessionsRepository.loadDetail', () {
    test('pairs the record with the newest buffer rows it returns', () async {
      final Harness harness = Harness(
        tables: sessionTables(
          sessions: [
            sessionRow(
              's1',
              status: 'active',
              startedAt: '2026-11-01T09:01:00.000Z',
            ),
          ],
          signals: [
            signalRow('g1'),
            signalRow('g2', kind: 'ice', sequence: 2),
          ],
        ),
      );

      final SessionDetail detail = await harness.okDetail('s1');

      expect(detail.familyId, 'f1');
      expect(detail.line.session.id, 's1');
      expect(detail.signals, hasLength(2));
      // family_id travels with the id, so a guessed id cannot reach another
      // family's session even before the policy acts. The second read is the
      // record lookup; the first is the caller's own membership row.
      expect(harness.rows.filters[1], {'family_id': 'f1', 'id': 's1'});
      // `webrtc_signals` has no family column; this read is scoped by session.
      expect(harness.rows.lastTable, TableName.webrtcSignals);
      expect(harness.rows.filters.last, {'session_id': 's1'});
      expect(harness.rows.orderings.last, 'created_at');
      expect(harness.rows.limits.last, SessionDetail.window);
    });

    test(
      'a session this account is not a participant of is unreadable',
      () async {
        final Harness harness = Harness(tables: sessionTables());

        final Result<SessionDetail?> read = await harness.subject.loadDetail(
          's9',
        );

        final HavenFailure? why = read.failureOrNull;
        expect(why, isA<ValidationFailure>());
        expect(
          (why as ValidationFailure).message,
          allOf(contains('not one this account can read'), contains('never')),
        );
      },
    );

    test('an unreadable buffer is a failure, not an empty buffer', () async {
      final Harness harness = Harness(
        withRows: FakeRowReader(sessionTables(sessions: [sessionRow('s1')]), {
          TableName.webrtcSignals: const BackendFailure(
            'fake: signals unreadable',
          ),
        }),
      );

      final Result<SessionDetail?> read = await harness.subject.loadDetail(
        's1',
      );

      expect(read.failureOrNull, isA<BackendFailure>());
    });

    test('an account with no family reads no record', () async {
      final Result<SessionDetail?> read = await Harness.withoutFamily().subject
          .loadDetail('s1');

      expect(read.valueOrNull, isNull);
    });

    test('the device name comes from the lane, or from nothing', () async {
      final Harness named = Harness(
        tables: sessionTables(sessions: [sessionRow('s1')]),
        withDevices: FakeDevicesRepository(
          devices: [device('d1', name: 'Ivy')],
        ),
      );

      expect((await named.okDetail('s1')).line.whose, 'Ivy');
    });
  });

  group('what a signalling row is allowed to say', () {
    test('the author is attributed without naming them', () async {
      final Harness harness = Harness(
        tables: sessionTables(
          sessions: [sessionRow('s1')],
          signals: [
            signalRow('g1', fromUserId: 'u1'),
            signalRow('g2', fromUserId: 'u2', kind: 'answer', sequence: 2),
          ],
        ),
      );

      final SessionDetail detail = await harness.okDetail('s1');

      expect(detail.signals.first.side, 'this account sent it');
      expect(
        detail.signals.last.side,
        'a row the record attributes to another account',
      );
      // No user id is rendered, whatever the row carries.
      expect(
        detail.signals.map((SignalLine l) => l.line).join(' '),
        isNot(contains('u2')),
      );
    });

    test('a payload is counted, not opened', () async {
      final Harness harness = Harness(
        tables: sessionTables(
          sessions: [sessionRow('s1')],
          signals: [
            signalRow(
              'g1',
              payload: const {'sdp': 'v=0 very private text', 'candidate': 'x'},
            ),
          ],
        ),
      );

      final SignalLine signal = (await harness.okDetail('s1')).signals.single;

      expect(signal.contents, '2 items in its payload, not shown here');
      expect(signal.line, isNot(contains('v=0')));
      // `sequence` has no default and no captured allocation rule, so the number
      // belongs to its writer rather than to an order this build asserts.
      expect(signal.order, 'numbered 1 by its writer');
    });

    test(
      'writing a row is refused with the grant that exists and the rule that does not',
      () async {
        final Harness harness = Harness(
          tables: sessionTables(sessions: [sessionRow('s1')]),
        );

        final SessionDetail detail = await harness.okDetail('s1');

        expect(
          detail.signalGap.message,
          'Haven cannot send a signalling row for a session in this build yet.',
        );
        expect(detail.signalGap.missing, contains('webrtc_signals'));
        expect(detail.signalGap.missing, contains('04-rls-matrix.md:159'));
        expect(detail.signalGap.missing, contains('sequence'));
        expect(detail.signalGap, same(SessionGaps.signalGap));
        expect(detail.mediaGap, same(SessionGaps.mediaGap));
      },
    );
  });
}
