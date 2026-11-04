import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/notifications/data/alerts_models.dart';
import 'package:haven_core/haven_core.dart';

import '../child_devices/fakes.dart';
import '../support/data_fakes.dart';
import 'fakes.dart';
import 'harness.dart';

void main() {
  group('HavenAlertsRepository.load', () {
    test('reads this family\'s reports and nothing else', () async {
      final Harness harness = Harness(
        tables: alertTables(
          alerts: [
            alertRow('a1'),
            alertRow('a2', severity: 'critical'),
          ],
        ),
      );

      final AlertBoard board = await harness.okBoard();

      expect(board.familyId, 'f1');
      expect(board.lines, hasLength(2));
      expect(harness.rows.lastTable, TableName.safetyAlerts);
      // The family id comes from the caller's own membership row.
      expect(harness.rows.filters.first, {'user_id': 'u1'});
      expect(harness.rows.filters.last, {'family_id': 'f1'});
      // Ordered on the captured index safety_alerts_family_created_idx
      // (family_id, created_at DESC) — A3-staging-load-v1.sql:591.
      expect(harness.rows.orderings.last, 'created_at');
      expect(harness.rows.limits.last, AlertBoard.window);
    });

    test('an unreadable table is a failure, not an empty list', () async {
      final Harness harness = Harness(
        withRows: FakeRowReader(alertTables(), {
          TableName.safetyAlerts: const BackendFailure('fake: rows unreadable'),
        }),
      );

      final Result<AlertBoard?> read = await harness.subject.load();

      expect(read.failureOrNull, isA<BackendFailure>());
    });

    test(
      'an account with no family reads no board rather than an empty one',
      () async {
        final Result<AlertBoard?> read = await Harness.withoutFamily().subject
            .load();

        expect(read.valueOrNull, isNull);
      },
    );

    test('the sentence the backend wrote arrives as it was written', () async {
      final AlertBoard board = await Harness(
        tables: alertTables(
          alerts: [
            alertRow(
              'a1',
              message: 'Ivy left School  —  12:04',
              type: 'geofence_exit',
            ),
          ],
        ),
      ).okBoard();

      expect(board.lines.single.said, 'Ivy left School  —  12:04');
      expect(board.lines.single.kind, 'Recorded as: Left a safe place');
    });

    test(
      'a type outside the CHECK is echoed, not filed under "other"',
      () async {
        final AlertBoard board = await Harness(
          tables: alertTables(alerts: [alertRow('a1', type: 'homework_done')]),
        ).okBoard();

        expect(
          board.lines.single.kind,
          'Recorded as something this build does not recognise (homework_done)',
        );
      },
    );

    test(
      'the addressee stays unnamed and its refusal travels with the rows',
      () async {
        final AlertBoard board = await Harness(
          tables: alertTables(alerts: [alertRow('a1')]),
        ).okBoard();

        expect(board.lines.single.whose, 'a device this build cannot name');
        expect(board.deviceGap, isA<BlockedFailure>());
      },
    );

    test('a readable device lane puts names back on the rows', () async {
      final AlertBoard board = await Harness(
        tables: alertTables(alerts: [alertRow('a1')]),
        withDevices: FakeDevicesRepository(
          devices: [device('d1', name: 'Ivy')],
        ),
      ).okBoard();

      expect(board.lines.single.whose, 'Ivy');
      expect(board.deviceGap, isNull);
    });

    test('what was stored beside a report is counted, not shown', () async {
      final AlertBoard board = await Harness(
        tables: alertTables(
          alerts: [
            alertRow(
              'a1',
              payload: const {
                'latitude': 51.5,
                'longitude': -0.12,
                'zone': 'School',
              },
            ),
          ],
        ),
      ).okBoard();

      expect(board.lines.single.notes, 3);
      expect(
        board.lines.single.payloadLine,
        '3 items stored with it, not shown here',
      );
      // `payload` is proven only to be a JSON object, so its keys stay unprinted.
      expect(
        board.lines.map((AlertLine l) => '${l.said} ${l.payloadLine}').join(),
        isNot(contains('51.5')),
      );
    });

    test(
      'an answered row is reported as a mark the screen cannot give',
      () async {
        final AlertBoard board = await Harness(
          tables: alertTables(
            alerts: [
              alertRow(
                'a1',
                acknowledgedAt: '2026-11-01T09:30:00.000Z',
                acknowledgedBy: 'u9',
              ),
              alertRow('a2'),
            ],
          ),
        ).okBoard();

        expect(board.answeredCount, 1);
        expect(board.lines.first.answer, 'answered 2026-11-01T09:30:00.000Z');
        expect(board.lines.last.answer, 'no one has answered it in the record');
        expect(
          board.answeredLine,
          contains('not something this screen can give'),
        );
        // `acknowledged_by` is a profile id and the profile lane cannot name it.
        expect(
          board.lines.map((AlertLine l) => l.answer).join(),
          isNot(contains('u9')),
        );
      },
    );
  });
}
