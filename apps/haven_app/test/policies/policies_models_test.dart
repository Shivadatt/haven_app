import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/policies/data/policies_models.dart';

import 'fakes.dart';

void main() {
  group('PolicyLine', () {
    test('a version is a number, a write time and an answer', () {
      final PolicyLine line = policyLine();

      expect(line.which, 'Version 4');
      expect(line.written, 'written 2026-11-01T09:00:00.000Z');
      expect(line.whose, 'a device this build cannot name');
      expect(line.outcome, 'No answer from the device yet');
      expect(line.answered, isNull);
      expect(line.trouble, isNull);
      expect(line.statusLabel, 'Waiting for the device');
    });

    test('a named device replaces the fallback', () {
      expect(policyLine(deviceName: 'Ivy phone').whose, 'Ivy phone');
    });

    test('each captured state has its own sentence', () {
      expect(
        policyLine(enforcementStatus: 'enforced').outcome,
        'The device said it applied this version',
      );
      expect(
        policyLine(enforcementStatus: 'failed').outcome,
        'The device said it could not apply this version',
      );
      expect(
        policyLine(enforcementStatus: 'unsupported').outcome,
        'The device said it cannot apply rules like this',
      );
    });

    test('an answer stamp only appears when the device column carries one', () {
      expect(
        policyLine(acknowledgedAt: '2026-11-01T09:30:00.000Z').answered,
        'answered 2026-11-01T09:30:00.000Z',
      );
      expect(
        policyLine(enforcementStatus: 'enforced').answered,
        isNull,
        reason: 'a status without an acknowledged_at is still no stamp',
      );
    });

    test('an unknown state keeps the row\'s own word in the sentence', () {
      final PolicyLine line = policyLine(enforcementStatus: 'ghostly');

      expect(line.outcome, contains('ghostly'));
      expect(line.statusLabel, 'Unrecognised');
    });
  });

  group('PolicyBoard', () {
    test('the count describes rows read, for the scope that was asked', () {
      expect(
        policyBoard(lines: [policyLine(), policyLine()]).counted,
        '2 versions read — the newest 10 rows the backend would give, '
        'for this family.',
      );
      expect(policyBoard(deviceId: 'd1').counted, contains('one device'));
      expect(policyBoard().counted, startsWith('0 versions read'));
    });

    test('only a device saying it applied counts as enforced', () {
      final PolicyBoard board = policyBoard(
        lines: [
          policyLine(enforcementStatus: 'enforced'),
          policyLine(enforcementStatus: 'pending'),
          policyLine(enforcementStatus: 'failed'),
        ],
      );

      expect(board.enforcedCount, 1);
      expect(
        board.enforcedLine,
        '1 of 3 carry an answer from a device saying it applied them.',
      );
    });

    test('the highest number read is not called the live rules', () {
      final PolicyBoard board = policyBoard(
        lines: [policyLine(version: 2), policyLine(version: 7)],
      );

      expect(board.highestVersionRead, 7);
      expect(
        board.newestLine,
        'Version 7 is the highest number among them. A number here is not '
        'the set of rules a device is following.',
      );
    });

    test('an empty list has no highest version to claim', () {
      expect(policyBoard().highestVersionRead, isNull);
      expect(policyBoard().hasLines, isFalse);
      expect(policyBoard(lines: [policyLine()]).hasLines, isTrue);
    });
  });
}
