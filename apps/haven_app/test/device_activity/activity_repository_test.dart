import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/device_activity/data/activity_models.dart';
import 'package:haven_core/haven_core.dart';

import '../child_devices/fakes.dart';
import '../support/data_fakes.dart';
import 'fakes.dart';
import 'harness.dart';

void main() {
  group('HavenActivityRepository', () {
    test(
      'reads the family by its own id, newest day first, within the window',
      () async {
        final Harness harness = Harness(
          tables: activityTables(usage: [usageRow('u1')]),
        );
        await harness.okBoard();

        expect(harness.rows.readTables, [
          TableName.familyMembers,
          TableName.usageDaily,
        ]);
        expect(harness.rows.filters.last, {'family_id': 'f1'});
        expect(harness.rows.orderings.last, 'day');
        expect(harness.rows.limits.last, UsageBoard.window);
      },
    );

    test('filters other families out even when the fake holds them', () async {
      final Harness harness = Harness(
        tables: activityTables(
          usage: [
            usageRow('u1'),
            usageRow('u2', deviceId: 'd9'),
          ],
        ),
      );
      harness.rows.tables[TableName.usageDaily]!.add({
        ...usageRow('u3'),
        'family_id': 'f2',
      });

      final UsageBoard read = await harness.okBoard();
      expect(read.lines, hasLength(2));
    });

    test('names the device when the device lane answers', () async {
      final Harness harness = Harness(
        tables: activityTables(usage: [usageRow('u1', deviceId: 'd1')]),
        withDevices: FakeDevicesRepository(devices: [device('d1')]),
      );

      final UsageBoard read = await harness.okBoard();
      expect(read.lines.single.whose, 'Ivy phone');
      expect(read.deviceGap, isNull);
    });

    test('carries the device refusal instead of inventing an owner', () async {
      final Harness harness = Harness(
        tables: activityTables(usage: [usageRow('u1')]),
      );

      final UsageBoard read = await harness.okBoard();
      expect(read.deviceGap, isA<BlockedFailure>());
      expect(read.lines.single.whose, 'a device this build cannot name');
    });

    test('a day-row whose device is not in the list stays unnamed', () async {
      final Harness harness = Harness(
        tables: activityTables(usage: [usageRow('u1', deviceId: 'd7')]),
        withDevices: FakeDevicesRepository(devices: [device('d1')]),
      );

      final UsageBoard read = await harness.okBoard();
      expect(read.deviceGap, isNull);
      expect(read.lines.single.whose, 'a device this build cannot name');
    });

    test(
      'an account with no family gets the setup answer, not a board',
      () async {
        final Harness harness = Harness(
          tables: {
            TableName.familyMembers: const <Map<String, Object?>>[],
            TableName.usageDaily: [usageRow('u1')],
          },
        );

        final Result<UsageBoard?> read = await harness.subject.load();
        expect(read.isOk, isTrue);
        expect(read.valueOrNull, isNull);
        expect(harness.rows.readTables, [TableName.familyMembers]);
      },
    );

    test(
      'a device id narrows the read but never replaces the family',
      () async {
        final Harness harness = Harness(
          tables: activityTables(
            usage: [
              usageRow('u1', deviceId: 'd1'),
              usageRow('u2', deviceId: 'd2'),
            ],
          ),
        );

        final Result<UsageBoard?> read = await harness.subject.load(
          deviceId: 'd1',
        );
        final UsageBoard narrowed = read.valueOrNull!;
        expect(harness.rows.filters.last, {
          'family_id': 'f1',
          'device_id': 'd1',
        });
        expect(narrowed.lines, hasLength(1));
        expect(narrowed.deviceId, 'd1');
        expect(narrowed.counted, '1 day-row read for one device.');
      },
    );

    test('a refused usage read stays the failure the backend gave', () async {
      final Harness harness = Harness(
        withRows: FakeRowReader(activityTables(), {
          TableName.usageDaily: const NetworkFailure('Offline.'),
        }),
      );

      final Result<UsageBoard?> read = await harness.subject.load();
      expect(read.failureOrNull, isA<NetworkFailure>());
      expect(read.failureOrNull, isNot(isA<BlockedFailure>()));
    });

    test('a refused sign-in is not dressed up as a missing family', () async {
      final Harness harness = Harness();
      harness.auth.failWith = const NetworkFailure('Offline.');

      final Result<UsageBoard?> read = await harness.subject.load();
      expect(read.failureOrNull, isA<NetworkFailure>());
      expect(harness.rows.readTables, isEmpty);
    });

    test('rows with no day and no label still reach the board', () async {
      final Harness harness = Harness(
        tables: activityTables(
          usage: [usageRow('u1', day: null, appLabel: '', lastUsedAt: null)],
        ),
      );

      final UsageLine only = (await harness.okBoard()).lines.single;
      expect(only.day, 'a day this row did not state');
      expect(only.appLabel, 'An app that reported no name');
      expect(only.lastUsed, 'the device did not report a last-used time');
    });

    test(
      'reading nothing reports nothing, and does not call it an error',
      () async {
        final UsageBoard read = await Harness().okBoard();
        expect(read.hasLines, isFalse);
        expect(read.counted, '0 day-rows read for this family.');
      },
    );

    test('the device lane is asked once per load, not once per row', () async {
      final Harness harness = Harness(
        tables: activityTables(
          usage: [usageRow('u1'), usageRow('u2'), usageRow('u3')],
        ),
        withDevices: FakeDevicesRepository(devices: [device('d1')]),
      );

      await harness.okBoard();
      expect(harness.devices.calls, ['pairedDevices']);
    });

    test(
      'the family id on the board is the one the membership row gave',
      () async {
        final Harness harness = Harness(
          tables: activityTables(usage: [usageRow('u1')]),
        );
        final UsageBoard read = await harness.okBoard();
        expect(read.familyId, 'f1');
      },
    );
  });
}
