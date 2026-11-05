import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

void main() {
  late LocalTables tables;
  late InMemoryLocalStore store;

  Map<String, Object?> family(String id, {String name = 'F'}) => {
    'id': id,
    'name': name,
  };

  setUp(() {
    store = InMemoryLocalStore();
    tables = LocalTables(store);
  });

  group('schema constraints and uniques', () {
    test('duplicate ids and missing ids are refused', () async {
      await tables.insert(TableName.families, family('f1'));
      final dup = await tables.insert(TableName.families, family('f1'));
      expect(dup.failureOrNull, isA<BackendFailure>());
      final noId = await tables.insert(TableName.families, {'name': 'x'});
      expect(noId.failureOrNull, isA<ValidationFailure>());
    });

    test('safe zones are unique on family + name', () async {
      await tables.insert(TableName.families, family('f1'));
      final zone = <String, Object?>{
        'id': 'z1',
        LocalSchema.familyIdColumn: 'f1',
        LocalSchema.nameColumn: 'Home',
      };
      await tables.insert(TableName.safeZones, zone);
      final clash = await tables.insert(
        TableName.safeZones,
        {...zone, 'id': 'z2'},
      );
      expect(clash.failureOrNull, isA<BackendFailure>());
    });

    test('usage daily is unique on device + day + package', () async {
      await tables.insert(TableName.families, family('f1'));
      await tables.insert(TableName.devices, {
        'id': 'd1',
        LocalSchema.familyIdColumn: 'f1',
      });
      final row1 = <String, Object?>{
        'id': 'u1',
        LocalSchema.familyIdColumn: 'f1',
        LocalSchema.deviceIdColumn: 'd1',
        LocalSchema.dayColumn: '2026-11-05',
        LocalSchema.packageNameColumn: 'com.example.app',
      };
      await tables.insert(TableName.usageDaily, row1);
      final clash = await tables.insert(
        TableName.usageDaily,
        {...row1, 'id': 'u2'},
      );
      expect(clash.failureOrNull, isA<BackendFailure>());
    });

    test('safe zone states are unique on zone + device', () async {
      await tables.insert(TableName.families, family('f1'));
      await tables.insert(TableName.devices, {
        'id': 'd1',
        LocalSchema.familyIdColumn: 'f1',
      });
      await tables.insert(TableName.safeZones, {
        'id': 'z1',
        LocalSchema.familyIdColumn: 'f1',
        LocalSchema.nameColumn: 'School',
      });
      final state1 = <String, Object?>{
        LocalSchema.zoneIdColumn: 'z1',
        LocalSchema.deviceIdColumn: 'd1',
        'inside': true,
      };
      await tables.insert(TableName.safeZoneStates, state1);
      final clash = await tables.insert(
        TableName.safeZoneStates,
        {...state1, 'inside': false},
      );
      expect(clash.failureOrNull, isA<BackendFailure>());
    });
  });

  group('foreign key enforcement', () {
    test('a device must name a family that exists', () async {
      final orphan = await tables.insert(
        TableName.devices,
        <String, Object?>{'id': 'd1', LocalSchema.familyIdColumn: 'nope'},
      );
      expect(orphan.failureOrNull, isA<BackendFailure>());
      await tables.insert(TableName.families, family('f1'));
      final ok = await tables.insert(
        TableName.devices,
        <String, Object?>{'id': 'd2', LocalSchema.familyIdColumn: 'f1'},
      );
      expect(ok.isOk, isTrue);
    });

    test('policies, alerts and pairing requests require valid parents', () async {
      await tables.insert(TableName.families, family('f1'));
      await tables.insert(TableName.devices, {
        'id': 'd1',
        LocalSchema.familyIdColumn: 'f1',
      });

      // Policy requires family and device
      final badPolicy = await tables.insert(TableName.devicePolicies, {
        'id': 'pol1',
        LocalSchema.familyIdColumn: 'f1',
        LocalSchema.deviceIdColumn: 'nonexistent',
      });
      expect(badPolicy.failureOrNull, isA<BackendFailure>());
      final goodPolicy = await tables.insert(TableName.devicePolicies, {
        'id': 'pol1',
        LocalSchema.familyIdColumn: 'f1',
        LocalSchema.deviceIdColumn: 'd1',
      });
      expect(goodPolicy.isOk, isTrue);

      // Alert requires family and device
      final goodAlert = await tables.insert(TableName.safetyAlerts, {
        'id': 'alt1',
        LocalSchema.familyIdColumn: 'f1',
        LocalSchema.deviceIdColumn: 'd1',
      });
      expect(goodAlert.isOk, isTrue);

      // Pairing request requires family
      final goodPairing = await tables.insert(TableName.pairingRequests, {
        'id': 'pr1',
        LocalSchema.familyIdColumn: 'f1',
      });
      expect(goodPairing.isOk, isTrue);
    });

    test('a family or device with children cannot be deleted', () async {
      await tables.insert(TableName.families, family('f1'));
      await tables.insert(TableName.devices, {
        'id': 'd1',
        LocalSchema.familyIdColumn: 'f1',
      });

      final refusedFamily = await tables.delete(
        TableName.families,
        eq: {'id': 'f1'},
      );
      expect(refusedFamily.isErr, isTrue);

      await tables.delete(TableName.devices, eq: {'id': 'd1'});
      expect((await tables.delete(TableName.families, eq: {'id': 'f1'})).isOk, isTrue);
    });

    test('delete without a filter is refused', () async {
      final refused = await tables.delete(TableName.families, eq: {});
      expect(refused.failureOrNull, isA<ValidationFailure>());
    });

    test('update re-checks constraints and a failed rename changes nothing', () async {
      await tables.insert(TableName.families, family('f1'));
      await tables.insert(TableName.families, family('f2'));
      final clash = await tables.update(
        TableName.families,
        {'id': 'f1'},
        eq: {'id': 'f2'},
      );
      expect(clash.isErr, isTrue);
      expect((await tables.count(TableName.families)).valueOrNull, 2);
    });
  });
}
