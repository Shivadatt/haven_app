import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/device_commands/data/commands_models.dart';

import 'fakes.dart';

void main() {
  group('CommandLine', () {
    test('a queued instruction says nobody picked it up', () {
      final CommandLine line = commandLine();

      expect(line.what, 'Ask the device for its location');
      expect(line.state, 'Queued — no device has picked it up');
      expect(line.whose, 'a device this build cannot name');
      expect(line.answered, isNull);
      expect(line.tries, isNull);
      expect(line.trouble, isNull);
    });

    test('a named addressee replaces the fallback', () {
      expect(commandLine(deviceName: 'Ivy phone').whose, 'Ivy phone');
    });

    test('sent is not done — only an answer changes the claim', () {
      final CommandLine line = commandLine(status: 'delivered');

      expect(line.statusLabel, 'Sent to the device');
      expect(line.state, 'Sent — the device has not answered');
      expect(line.command.isAcknowledged, isFalse);
    });

    test('the write time is the row\'s own', () {
      expect(
        commandLine(createdAt: '2026-11-01T09:00:00.000Z').when,
        'written 2026-11-01T09:00:00.000Z',
      );
    });

    test('an answer and its stamp travel together', () {
      final CommandLine line = commandLine(
        status: 'succeeded',
        ackedAt: '2026-11-01T09:05:00.000Z',
        attempts: 2,
      );

      expect(line.state, 'The device answered that it is done');
      expect(line.answered, 'answered 2026-11-01T09:05:00.000Z');
      expect(line.tries, '2 tries');
    });

    test(
      'a type outside the CHECK list is not given a label it does not have',
      () {
        expect(commandLine(type: 'mystery').what, isNot('An instruction'));
        expect(commandLine(type: 'mystery').what, contains('cannot name'));
      },
    );
  });

  group('CommandBoard', () {
    test('the count describes rows read, for the scope that was asked', () {
      expect(
        cmdBoard(lines: [commandLine(), commandLine()]).counted,
        '2 instructions read — the newest 25 rows the backend would give, '
        'for this family.',
      );
      expect(cmdBoard(deviceId: 'd1').counted, contains('one device'));
      expect(cmdBoard().counted, startsWith('0 instructions read'));
    });

    test('only rows carrying an answer are counted as answered', () {
      final CommandBoard board = cmdBoard(
        lines: [
          commandLine(ackedAt: '2026-11-01T09:05:00.000Z'),
          commandLine(),
        ],
      );

      expect(board.answeredCount, 1);
      expect(board.answeredLine, '1 of 2 carry an answer from a device.');
    });

    test('an empty log is still a log that was read', () {
      expect(cmdBoard().hasLines, isFalse);
      expect(cmdBoard(lines: [commandLine()]).hasLines, isTrue);
    });
  });
}
