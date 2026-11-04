import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/core/errors/captured_gaps.dart';
import 'package:haven_app/features/telemetry/data/telemetry_models.dart';
import 'package:haven_core/haven_core.dart';

import '../child_devices/fakes.dart';
import '../support/data_fakes.dart';
import 'fakes.dart';
import 'harness.dart';

void main() {
  group('HavenTelemetryRepository.load', () {
    test('reads this family\'s entries and nothing else', () async {
      final Harness harness = Harness(
        tables: trailTables(rows: [auditRow('a1'), auditRow('a2')]),
      );

      final TelemetryBoard board = await harness.okBoard();

      expect(board.familyId, 'f1');
      expect(board.lines, hasLength(2));
      expect(harness.rows.lastTable, TableName.auditLogs);
      // The family id comes from the caller's own membership row, never from a
      // value the screen was handed. `audit_logs` is readable by a parent of the
      // family only (04-rls-matrix.md:40), so this filter is the whole scope.
      expect(harness.rows.filters.first, {'user_id': 'u1'});
      expect(harness.rows.filters.last, {'family_id': 'f1'});
      expect(harness.rows.orderings.last, 'created_at');
      expect(harness.rows.limits.last, TelemetryBoard.window);
    });

    test(
      'a device id narrows the read but never replaces the family',
      () async {
        final Harness harness = Harness(
          tables: trailTables(
            rows: [
              auditRow('a1'),
              auditRow('a2', deviceId: 'd2'),
            ],
          ),
        );

        final TelemetryBoard board = await harness.okBoard(deviceId: 'd2');

        expect(harness.rows.filters.last, {
          'family_id': 'f1',
          'device_id': 'd2',
        });
        expect(board.deviceId, 'd2');
        expect(board.lines, hasLength(1));
        expect(board.counted, contains('one device'));
      },
    );

    test('an entry with no device is still an entry', () async {
      final TelemetryBoard board = await Harness(
        tables: trailTables(rows: [auditRow('a1', deviceId: null)]),
      ).okBoard();

      expect(board.lines, hasLength(1));
      expect(board.lines.single.whose, isNull);
    });

    test('a readable device lane names the entries that carry an id', () async {
      final TelemetryBoard board = await Harness(
        tables: trailTables(rows: [auditRow('a1')]),
        withDevices: FakeDevicesRepository(
          devices: [device('d1', name: 'Ivy')],
        ),
      ).okBoard();

      expect(board.lines.single.whose, 'Ivy');
      expect(board.deviceGap, isNull);
    });

    test('an unreadable log is a failure, not an empty trail', () async {
      final Harness harness = Harness(
        withRows: FakeRowReader(trailTables(), {
          TableName.auditLogs: const BackendFailure('fake: rows unreadable'),
        }),
      );

      final Result<TelemetryBoard?> read = await harness.subject.load();

      expect(read.failureOrNull, isA<BackendFailure>());
    });

    test(
      'an account with no family reads no board rather than an empty one',
      () async {
        final Result<TelemetryBoard?> read = await Harness.withoutFamily()
            .subject
            .load();

        expect(read.valueOrNull, isNull);
      },
    );
  });

  group('the two refusals the trail carries', () {
    test('online status is refused, citing both closed lanes', () async {
      final TelemetryBoard board = await Harness(
        tables: trailTables(rows: [auditRow('a1')]),
      ).okBoard();

      expect(
        board.offlineGap.message,
        'Haven cannot say whether a device is online in this build yet.',
      );
      expect(board.offlineGap.missing, contains('detect_offline_devices'));
      expect(
        board.offlineGap.missing,
        contains(CapturedGaps.deviceLaneMissing),
        reason:
            'the devices half of the claim is the shared F6 sentence, '
            'stated once',
      );
      expect(board.offlineGap.missing, contains(CapturedGaps.rpcLaneMissing));
      expect(
        board.offlineGap.detail,
        startsWith('BLOCKED — SPECIFICATION REQUIRED:'),
      );
    });

    test('the device lane\'s own refusal travels unchanged', () async {
      final TelemetryBoard board = await Harness(
        tables: trailTables(rows: [auditRow('a1')]),
      ).okBoard();

      expect(
        board.deviceGap!.missing,
        contains('fake: no contract for listing devices'),
      );
    });
  });

  group('row to line', () {
    test(
      'an event type is echoed, never mapped onto an invented category',
      () async {
        final AuditLine line = (await Harness(
          tables: trailTables(
            rows: [auditRow('a1', eventType: 'something.new')],
          ),
        ).okBoard()).lines.single;

        expect(line.what, 'Recorded as: something.new');
        expect(line.when, 'at 2026-11-01T09:00:00.000Z');
        expect(line.about, 'about something recorded as a device');
      },
    );

    test('an entry with no target reads as a family-level change', () async {
      final AuditLine line = (await Harness(
        tables: trailTables(rows: [auditRow('a1', targetType: null)]),
      ).okBoard()).lines.single;

      expect(line.about, 'about the family as a whole');
    });

    test('metadata is counted, not printed', () async {
      final AuditLine line = (await Harness(
        tables: trailTables(
          rows: [
            auditRow(
              'a1',
              metadata: const {'secret_note': 'a-value-nobody-specified'},
            ),
          ],
        ),
      ).okBoard()).lines.single;

      expect(line.notes, '1 note(s) stored with it, not shown here');
      expect(line.notes, isNot(contains('a-value-nobody-specified')));
    });

    test('an entry with nothing stored reads as nothing stored', () async {
      final AuditLine line = (await Harness(
        tables: trailTables(rows: [auditRow('a1', metadata: const {})]),
      ).okBoard()).lines.single;

      expect(line.notes, 'nothing else was stored with it');
    });
  });
}
