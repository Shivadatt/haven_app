import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/device_activity/data/activity_models.dart';

import 'fakes.dart';

/// The wording on this screen is the product: a parent comparing two apps reads
/// these strings, so they are tested against the column they come from and never
/// against a figure the row does not carry.
void main() {
  group('UsageLine', () {
    test('states the day the row is for', () {
      expect(line().day, '1/11/2026');
    });

    test('says so when the row carries no day', () {
      expect(line(day: null).day, 'a day this row did not state');
    });

    test('formats a whole total as hours and minutes', () {
      expect(line(totalMs: 4_500_000).duration, '1 h 15 m');
    });

    test('pads minutes below an hour so two rows line up', () {
      expect(line(totalMs: 3_720_000).duration, '1 h 02 m');
    });

    test('formats a short total as minutes, and a very short one plainly', () {
      expect(line(totalMs: 90_000).duration, '1 m');
      expect(line(totalMs: 59_999).duration, 'under a minute');
    });

    test('reports no time rather than rounding up to a minute', () {
      expect(line(totalMs: 0).duration, 'no time reported');
      expect(line(totalMs: -1).duration, 'no time reported');
    });

    test('names the owner when the device was readable', () {
      expect(line(deviceName: 'Ivy phone').whose, 'Ivy phone');
      expect(line().whose, 'a device this build cannot name');
    });

    test('falls back to the package the row still names', () {
      expect(line(app: '').appLabel, 'An app that reported no name');
    });

    test('gives the last-used instant in UTC, or says there is none', () {
      expect(line().lastUsed, 'last used 2026-11-01T18:04:00.000Z');
      expect(line(lastUsedAt: null).lastUsed, contains('did not report'));
    });

    test('the row is kept whole, so the screen can still say what it read', () {
      final UsageLine only = line(app: 'Mapler');
      expect(only.usage.packageName, 'com.example.map');
      expect(only.usage.source, 'usage_stats');
    });
  });

  group('UsageBoard', () {
    test('counts rows read, singular and plural', () {
      expect(board().counted, '0 day-rows read for this family.');
      expect(board(lines: [line()]).counted, '1 day-row read for this family.');
      expect(
        board(lines: [line(), line()]).counted,
        '2 day-rows read for this family.',
      );
    });

    test('knows an empty read from a failed one', () {
      expect(board().hasLines, isFalse);
      expect(board(lines: [line()]).hasLines, isTrue);
    });

    test('the window is a page size, and the board says only what it read', () {
      expect(
        UsageBoard.window,
        greaterThan(0),
        reason: 'a screen that reads nothing cannot bound anything',
      );
      expect(
        board(
          lines: [for (int i = 0; i < UsageBoard.window; i++) line()],
        ).lines,
        hasLength(UsageBoard.window),
      );
    });
  });
}
