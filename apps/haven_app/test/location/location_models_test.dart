import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/core/errors/captured_gaps.dart';
import 'package:haven_app/features/location/data/location_models.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'fakes.dart';

/// The wording on this screen is the whole product: a parent decides whether
/// their child is somewhere safe from these sentences, so each one is pinned to
/// the column it comes from.
void main() {
  group('FixLine', () {
    test('quotes the instant the device took the reading', () {
      expect(fixLine().recorded, 'reported at 2026-11-01T09:00:00.000Z');
    });

    test('states the accuracy the row carried, in metres', () {
      expect(fixLine(accuracyM: 12).accuracy, 'to within about 12 m');
      expect(fixLine(accuracyM: 48.6).accuracy, 'to within about 49 m');
    });

    test('switches to kilometres above a thousand metres', () {
      expect(fixLine(accuracyM: 1500).accuracy, 'to within about 1.5 km');
    });

    test('reports no accuracy figure instead of claiming an exact place', () {
      expect(fixLine(accuracyM: 0).accuracy, contains('no accuracy figure'));
      expect(fixLine(accuracyM: -5).accuracy, contains('no accuracy figure'));
    });

    test('gives the delivery lag the two timestamps actually show', () {
      expect(fixLine().delay, 'reached Haven within a minute');
      expect(
        fixLine(receivedAt: '2026-11-01T09:07:00.000Z').delay,
        'reached Haven 7 minutes later',
      );
      expect(
        fixLine(receivedAt: '2026-11-01T11:00:00.000Z').delay,
        'reached Haven 2 h later',
      );
    });

    test('calls an impossible lag what it is', () {
      expect(
        fixLine(receivedAt: '2026-11-01T08:00:00.000Z').delay,
        'the backend stamped this as received before it was reported',
      );
    });

    test('carries the coordinates exactly as the row holds them', () {
      expect(fixLine().coordinates, '37.7749, -122.4194');
    });

    test('echoes the source rather than interpreting it', () {
      expect(fixLine().source, 'as reported by fused');
    });

    test('names the owner only when a device row named it first', () {
      expect(fixLine(deviceName: 'Ivy phone').whose, 'Ivy phone');
      expect(fixLine().whose, 'a device this build cannot name');
    });
  });

  group('FixBoard', () {
    test('counts the fixes read and bounds them by the window', () {
      expect(board().counted, startsWith('0 reported places read'));
      expect(
        board(lines: [fixLine()]).counted,
        startsWith(
          '1 reported place '
          'read',
        ),
      );
      expect(
        board(lines: [fixLine(), fixLine()]).counted,
        startsWith(
          '2 '
          'reported places read',
        ),
      );
    });

    test('says whose rows they are when the read was narrowed', () {
      expect(board().counted, contains('this family'));
      expect(board(deviceId: 'd1').counted, contains('one device'));
    });

    test('a present board with no rows is not a failure', () {
      expect(board().hasLines, isFalse);
      expect(board(lines: [fixLine()]).hasLines, isTrue);
    });

    test('the window bounds the read, and is not a promise about history', () {
      expect(FixBoard.window, greaterThan(0));
      expect(board().counted, contains('${FixBoard.window} rows'));
    });

    test('the presence gap is the captured sentence, not a paraphrase', () {
      final BlockedFailure gap = board().presenceGap;
      expect(gap.missing, CapturedGaps.presenceLaneMissing);
      expect(gap.message, contains('inside a safe place'));
      expect(
        gap.detail,
        'BLOCKED — SPECIFICATION REQUIRED: ${CapturedGaps.presenceLaneMissing}',
      );
    });

    test('an unknown device id keeps the fix unnamed without a fake name', () {
      final LocationEvent raw = LocationEvent(
        id: 'l9',
        deviceId: 'd-none',
        familyId: 'f1',
        lat: 1,
        lng: 2,
        accuracyM: 5,
        recordedAt: DateTime.utc(2026, 11, 1),
        receivedAt: DateTime.utc(2026, 11, 1),
        source: 'gps',
      );
      expect(FixLine(raw).whose, contains('cannot name'));
    });
  });
}
