import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/core/errors/captured_gaps.dart';
import 'package:haven_app/features/location/data/location_models.dart';
import 'package:haven_core/haven_core.dart';

import '../child_devices/fakes.dart';
import '../support/data_fakes.dart';
import 'fakes.dart';
import 'harness.dart';

void main() {
  group('HavenLocationRepository', () {
    test(
      'reads the family by its own id, newest fix first, within the window',
      () async {
        final Harness harness = Harness(
          tables: locationTables(fixes: [locationRow('l1')]),
        );
        await harness.okBoard();

        expect(harness.rows.readTables, [
          TableName.familyMembers,
          TableName.locationEvents,
        ]);
        expect(harness.rows.filters.last, {'family_id': 'f1'});
        expect(harness.rows.orderings.last, 'recorded_at');
        expect(harness.rows.limits.last, FixBoard.window);
      },
    );

    test(
      'a device id narrows the read but never replaces the family',
      () async {
        final Harness harness = Harness(
          tables: locationTables(
            fixes: [
              locationRow('l1'),
              locationRow('l2', deviceId: 'd2'),
            ],
          ),
        );

        final FixBoard narrowed = await harness.okBoard(deviceId: 'd1');
        expect(harness.rows.filters.last, {
          'family_id': 'f1',
          'device_id': 'd1',
        });
        expect(narrowed.lines, hasLength(1));
        expect(narrowed.deviceId, 'd1');
      },
    );

    test(
      'a row from another family is not read, filter or no filter',
      () async {
        final Harness harness = Harness(
          tables: locationTables(fixes: [locationRow('l1')]),
        );
        harness.rows.tables[TableName.locationEvents]!.add({
          ...locationRow('l2'),
          'family_id': 'f2',
        });

        final FixBoard read = await harness.okBoard();
        expect(read.lines, hasLength(1));
      },
    );

    test('names the device when the device lane answers', () async {
      final Harness harness = Harness(
        tables: locationTables(fixes: [locationRow('l1', deviceId: 'd1')]),
        withDevices: FakeDevicesRepository(devices: [device('d1')]),
      );

      final FixBoard read = await harness.okBoard();
      expect(read.lines.single.whose, 'Ivy phone');
      expect(read.deviceGap, isNull);
    });

    test('carries the device refusal instead of inventing an owner', () async {
      final FixBoard read = await Harness(
        tables: locationTables(fixes: [locationRow('l1')]),
      ).okBoard();

      expect(read.deviceGap, isA<BlockedFailure>());
      expect(read.lines.single.whose, 'a device this build cannot name');
    });

    test('the presence refusal is on every board, readable or not', () async {
      final FixBoard empty = await Harness().okBoard();
      final FixBoard filled = await Harness(
        tables: locationTables(fixes: [locationRow('l1')]),
      ).okBoard();

      expect(empty.presenceGap.missing, CapturedGaps.presenceLaneMissing);
      expect(filled.presenceGap.missing, CapturedGaps.presenceLaneMissing);
      expect(
        empty.presenceGap.detail,
        startsWith('BLOCKED — SPECIFICATION REQUIRED:'),
      );
    });

    test(
      'an account with no family gets the setup answer, not a board',
      () async {
        final Harness harness = Harness(
          tables: {
            TableName.familyMembers: const <Map<String, Object?>>[],
            TableName.locationEvents: [locationRow('l1')],
          },
        );

        final Result<FixBoard?> read = await harness.subject.load();
        expect(read.isOk, isTrue);
        expect(read.valueOrNull, isNull);
        expect(harness.rows.readTables, [TableName.familyMembers]);
      },
    );

    test('a refused fix read stays the failure the backend gave', () async {
      final Harness harness = Harness(
        withRows: FakeRowReader(locationTables(), {
          TableName.locationEvents: const NetworkFailure('Offline.'),
        }),
      );

      final Result<FixBoard?> read = await harness.subject.load();
      expect(read.failureOrNull, isA<NetworkFailure>());
      expect(read.failureOrNull, isNot(isA<BlockedFailure>()));
    });

    test('a refused sign-in is not dressed up as a missing family', () async {
      final Harness harness = Harness();
      harness.auth.failWith = const NetworkFailure('Offline.');

      final Result<FixBoard?> read = await harness.subject.load();
      expect(read.failureOrNull, isA<NetworkFailure>());
      expect(harness.rows.readTables, isEmpty);
    });

    test('the device lane is asked once per load, not once per fix', () async {
      final Harness harness = Harness(
        tables: locationTables(
          fixes: [locationRow('l1'), locationRow('l2'), locationRow('l3')],
        ),
        withDevices: FakeDevicesRepository(devices: [device('d1')]),
      );

      await harness.okBoard();
      expect(harness.devices.calls, ['pairedDevices']);
    });

    test(
      'reading nothing reports nothing and still states the boundary',
      () async {
        final FixBoard read = await Harness().okBoard();
        expect(read.hasLines, isFalse);
        expect(read.counted, contains('0 reported places read'));
        expect(read.counted, contains('${FixBoard.window} rows'));
      },
    );
  });
}
