import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/device_commands/data/commands_models.dart';
import 'package:haven_core/haven_core.dart';

import '../child_devices/fakes.dart';
import '../support/data_fakes.dart';
import 'fakes.dart';
import 'harness.dart';

void main() {
  group('HavenCommandsRepository.load', () {
    test('reads this family\'s instructions and nothing else', () async {
      final Harness harness = Harness(
        tables: commandTables(rows: [commandRow('c1'), commandRow('c2')]),
      );

      final CommandBoard board = await harness.okBoard();

      expect(board.familyId, 'f1');
      expect(board.lines, hasLength(2));
      expect(harness.rows.lastTable, TableName.deviceCommands);
      // The family id comes from the caller's own membership row, never from a
      // value the route could have been handed.
      expect(harness.rows.filters.first, {'user_id': 'u1'});
      expect(harness.rows.filters.last, {'family_id': 'f1'});
      expect(harness.rows.orderings.last, 'created_at');
      expect(harness.rows.limits.last, CommandBoard.window);
    });

    test(
      'a device id narrows the read but never replaces the family',
      () async {
        final Harness harness = Harness(
          tables: commandTables(
            rows: [
              commandRow('c1'),
              commandRow('c2', deviceId: 'd2'),
            ],
          ),
        );

        final CommandBoard board = await harness.okBoard(deviceId: 'd2');

        expect(harness.rows.filters.last, {
          'family_id': 'f1',
          'device_id': 'd2',
        });
        expect(board.deviceId, 'd2');
        expect(board.lines, hasLength(1));
        expect(board.counted, contains('one device'));
      },
    );

    test(
      'the addressee stays unnamed and the reason travels with the rows',
      () async {
        final Harness harness = Harness(
          tables: commandTables(rows: [commandRow('c1')]),
        );

        final CommandBoard board = await harness.okBoard();

        expect(board.lines.single.whose, 'a device this build cannot name');
        expect(
          board.deviceGap,
          isA<BlockedFailure>(),
          reason: 'the device lane refused, so the board carries that refusal',
        );
      },
    );

    test('a readable device lane puts names back on the rows', () async {
      final Harness harness = Harness(
        tables: commandTables(
          rows: [
            commandRow('c1'),
            commandRow('c2', deviceId: 'd9'),
          ],
        ),
        withDevices: FakeDevicesRepository(
          devices: [
            device('d1', name: 'Sam\'s phone'),
            device('d9', name: ''),
          ],
        ),
      );

      final CommandBoard board = await harness.okBoard();

      expect(board.lines.first.whose, 'Sam\'s phone');
      // A device row with no display name is not a name; the fallback stays.
      expect(board.lines.last.whose, 'a device this build cannot name');
    });

    test(
      'an unreadable instruction table is a failure, not an empty log',
      () async {
        final Harness harness = Harness(
          withRows: FakeRowReader(commandTables(), {
            TableName.deviceCommands: const BackendFailure(
              'fake: rows unreadable',
            ),
          }),
        );

        final Result<CommandBoard?> read = await harness.subject.load();

        expect(read.failureOrNull, isA<BackendFailure>());
      },
    );

    test(
      'an account with no family reads no board rather than an empty one',
      () async {
        final Result<CommandBoard?> read = await Harness.withoutFamily().subject
            .load();

        expect(read.valueOrNull, isNull);
      },
    );

    test(
      'the write refusal is the captured evidence, not a paraphrase',
      () async {
        final CommandBoard board = await Harness(
          tables: commandTables(rows: [commandRow('c1')]),
        ).okBoard();

        expect(
          board.writeGap.message,
          'Haven cannot send, cancel or answer an instruction in this build yet.',
        );
        expect(board.writeGap.missing, contains('04-rls-matrix.md:99-101'));
        expect(board.writeGap.missing, contains('poll_device_commands'));
        expect(board.writeGap.missing, contains('expire_stale_commands'));
        expect(
          board.writeGap.detail,
          startsWith('BLOCKED — SPECIFICATION REQUIRED:'),
        );
      },
    );
  });

  group('HavenCommandsRepository rows to lines', () {
    test('a row keeps the state and the answer the device gave', () async {
      final Harness harness = Harness(
        tables: commandTables(
          rows: [
            commandRow(
              'c1',
              type: 'apply_policy',
              status: 'failed',
              attempts: 3,
              ackedAt: '2026-11-01T09:02:00.000Z',
              errorMessage: 'fake: the device refused',
            ),
          ],
        ),
      );

      final CommandLine line = (await harness.okBoard()).lines.single;

      expect(line.what, 'Apply the current rules');
      expect(line.statusLabel, 'Failed');
      expect(line.state, 'The device answered that it could not');
      expect(line.tries, '3 tries');
      expect(line.trouble, 'fake: the device refused');
      expect(line.answered, contains('2026-11-01T09:02:00.000Z'));
      expect(line.command.isAcknowledged, isTrue);
    });

    test('a state outside the CHECK list is echoed, not relabelled', () async {
      final Harness harness = Harness(
        tables: commandTables(rows: [commandRow('c1', status: 'ghostly')]),
      );

      final CommandLine line = (await harness.okBoard()).lines.single;

      expect(line.state, contains('ghostly'));
      expect(line.statusLabel, 'Unrecognised');
    });
  });
}
