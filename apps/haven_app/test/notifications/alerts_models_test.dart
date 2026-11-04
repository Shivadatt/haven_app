import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/notifications/data/alerts_models.dart';

import 'fakes.dart';

void main() {
  group('AlertLine repeats the row, not an interpretation', () {
    test('the backend\'s sentence is shown as it arrived', () {
      expect(
        alertLine(message: 'Ivy  left   School — again').said,
        'Ivy  left   School — again',
      );
    });

    test('a known type becomes the captured label, prefixed', () {
      expect(
        alertLine(type: 'geofence_exit').kind,
        'Recorded as: Left a safe place',
      );
      expect(
        alertLine(type: 'low_battery').kind,
        'Recorded as: Battery is low',
      );
      expect(alertLine(type: 'other').kind, 'Recorded as: Something else');
    });

    test('a type outside the CHECK is echoed rather than filed under other', () {
      expect(
        alertLine(type: 'screenshot_taken').kind,
        'Recorded as something this build does not recognise (screenshot_taken)',
      );
    });

    test('an unrecognised severity is not promoted to an alarm', () {
      expect(
        alertLine(severity: 'critical').severityLabel,
        'Needs attention now',
      );
      expect(alertLine(severity: 'info').severityLabel, 'For information');
      expect(alertLine(severity: 'urgent').severityLabel, 'Unrecognised');
    });

    test('an answer on the row is dated, not credited', () {
      expect(
        alertLine(acknowledged: true).answer,
        'answered 2026-11-01T09:30:00.000Z',
      );
      expect(alertLine().answer, 'no one has answered it in the record');
    });

    test('a payload is a count of items, never their contents', () {
      expect(alertLine().payloadLine, 'nothing else was stored with it');
      expect(alertLine().notes, 0);
      expect(
        alertLine(payload: const {'zone': 'School'}).payloadLine,
        '1 item stored with it, not shown here',
      );
      expect(
        alertLine(payload: const {'a': 1, 'b': 2}).payloadLine,
        '2 items stored with it, not shown here',
      );
      expect(alertLine(payload: const {'a': 1, 'b': 2}).notes, 2);
    });

    test('an unnamed device stays unnamed in words the screen can show', () {
      expect(alertLine().whose, 'a device this build cannot name');
      expect(alertLine(deviceName: 'Ivy').whose, 'Ivy');
    });

    test('the row is dated in UTC, the way the column is read', () {
      expect(alertLine().when, 'at 2026-11-01T09:00:00.000Z');
    });
  });

  group('AlertBoard counts what was read', () {
    test('the count names the window, not a history', () {
      expect(
        alertBoard(lines: [alertLine()]).counted,
        '1 report read — the newest ${AlertBoard.window} rows the backend would '
        'give for this family.',
      );
      expect(
        alertBoard(lines: [alertLine(), alertLine()]).counted,
        startsWith('2 reports read'),
      );
    });

    test('answered rows are counted and the mark is disowned', () {
      final AlertBoard board = alertBoard(
        lines: [
          alertLine(acknowledged: true),
          alertLine(id: 'a2'),
        ],
      );

      expect(board.answeredCount, 1);
      expect(
        board.answeredLine,
        '1 of 2 are marked as answered in the record. That mark is not something '
        'this screen can give a row.',
      );
    });

    test('the attention sentence follows the rows', () {
      expect(
        alertBoard().severityLine,
        'None of the rows read is marked as needing attention now.',
      );
      expect(
        alertBoard(lines: [alertLine(severity: 'critical')]).severityLine,
        '1 row is marked as needing attention now.',
      );
      expect(
        alertBoard(
          lines: [
            alertLine(severity: 'critical'),
            alertLine(id: 'a2', severity: 'critical'),
          ],
        ).severityLine,
        '2 rows are marked as needing attention now.',
      );
    });

    test('an unrecognised severity is not counted as needing attention', () {
      expect(
        alertBoard(lines: [alertLine(severity: 'urgent')]).criticalCount,
        0,
      );
    });

    test('an empty list is not an error', () {
      final AlertBoard board = alertBoard();

      expect(board.hasLines, isFalse);
      expect(board.lines, isEmpty);
      expect(board.answeredCount, 0);
    });
  });
}
