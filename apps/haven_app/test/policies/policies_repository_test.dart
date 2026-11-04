import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/policies/data/policies_models.dart';
import 'package:haven_core/haven_core.dart';

import '../child_devices/fakes.dart';
import '../support/data_fakes.dart';
import 'fakes.dart';
import 'harness.dart';

void main() {
  group('HavenPoliciesRepository.load', () {
    test('reads this family\'s versions and nothing else', () async {
      final Harness harness = Harness(
        tables: policyTables(rows: [policyRow('p1'), policyRow('p2')]),
      );

      final PolicyBoard board = await harness.okBoard();

      expect(board.familyId, 'f1');
      expect(board.lines, hasLength(2));
      expect(harness.rows.lastTable, TableName.devicePolicies);
      // The family id comes from the caller's own membership row, never from a
      // value the route could have been handed.
      expect(harness.rows.filters.first, {'user_id': 'u1'});
      expect(harness.rows.filters.last, {'family_id': 'f1'});
      expect(harness.rows.orderings.last, 'created_at');
      expect(harness.rows.limits.last, PolicyBoard.window);
    });

    test(
      'a device id narrows the read but never replaces the family',
      () async {
        final Harness harness = Harness(
          tables: policyTables(
            rows: [
              policyRow('p1'),
              policyRow('p2', deviceId: 'd2'),
            ],
          ),
        );

        final PolicyBoard board = await harness.okBoard(deviceId: 'd2');

        expect(harness.rows.filters.last, {
          'family_id': 'f1',
          'device_id': 'd2',
        });
        expect(board.deviceId, 'd2');
        expect(board.lines.single.policy.deviceId, 'd2');
        expect(board.counted, contains('one device'));
      },
    );

    test('an id from another family reads nothing, because the filter is '
        'the caller\'s own', () async {
      final Harness harness = Harness(
        tables: policyTables(rows: [policyRow('p1')]),
      );

      final PolicyBoard board = await harness.okBoard(deviceId: 'd999');

      expect(board.lines, isEmpty);
      expect(harness.rows.filters.last, contains('family_id'));
    });

    test(
      'the addressee stays unnamed and the reason travels with the rows',
      () async {
        final PolicyBoard board = await Harness(
          tables: policyTables(rows: [policyRow('p1')]),
        ).okBoard();

        expect(board.lines.single.whose, 'a device this build cannot name');
        expect(board.deviceGap, isA<BlockedFailure>());
      },
    );

    test('a readable device lane puts names back on the rows', () async {
      final PolicyBoard board = await Harness(
        tables: policyTables(rows: [policyRow('p1'), policyRow('p2')]),
        withDevices: FakeDevicesRepository(
          devices: [device('d1', name: 'Ivy')],
        ),
      ).okBoard();

      expect(board.lines.first.whose, 'Ivy');
      expect(board.lines.last.whose, 'Ivy');
    });

    test(
      'an unreadable version table is a failure, not an empty list',
      () async {
        final Harness harness = Harness(
          withRows: FakeRowReader(policyTables(), {
            TableName.devicePolicies: const BackendFailure(
              'fake: rows unreadable',
            ),
          }),
        );

        final Result<PolicyBoard?> read = await harness.subject.load();

        expect(read.failureOrNull, isA<BackendFailure>());
      },
    );

    test(
      'an account with no family reads no board rather than an empty one',
      () async {
        final Result<PolicyBoard?> read = await Harness.withoutFamily().subject
            .load();

        expect(read.valueOrNull, isNull);
      },
    );
  });

  group('row to line', () {
    test('an enforced version is the only one that reads as applied', () async {
      final Harness harness = Harness(
        tables: policyTables(
          rows: [
            policyRow(
              'p1',
              enforcementStatus: 'enforced',
              acknowledgedAt: '2026-11-01T09:03:00.000Z',
            ),
            policyRow('p2', enforcementStatus: 'pending'),
          ],
        ),
      );

      final PolicyBoard board = await harness.okBoard();

      expect(
        board.lines.first.outcome,
        'The device said it applied this version',
      );
      expect(board.lines.first.policy.isEnforcedOnDevice, isTrue);
      expect(board.lines.last.outcome, 'No answer from the device yet');
      expect(board.enforcedCount, 1);
    });

    test('a state outside the CHECK list is echoed, not relabelled', () async {
      final PolicyLine line = (await Harness(
        tables: policyTables(
          rows: [policyRow('p1', enforcementStatus: 'ghostly')],
        ),
      ).okBoard()).lines.single;

      expect(line.outcome, contains('ghostly'));
      expect(line.statusLabel, 'Unrecognised');
    });

    test('a device error travels as the device\'s own words', () async {
      final PolicyLine line = (await Harness(
        tables: policyTables(
          rows: [
            policyRow(
              'p1',
              enforcementStatus: 'failed',
              lastError: 'fake: the profile owner refused',
            ),
          ],
        ),
      ).okBoard()).lines.single;

      expect(line.trouble, 'fake: the profile owner refused');
      expect(line.outcome, 'The device said it could not apply this version');
    });
  });
}
