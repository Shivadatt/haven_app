import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/child_devices/data/local_devices_repository.dart';
import 'package:haven_app/features/family/data/family_scope.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../support/fakes.dart';

void main() {
  const AuthSession session = AuthSession(
    userId: 'u1',
    email: 'parent@example.com',
    accessToken: 'test-token',
  );

  late LocalTables tables;
  late LocalRowReader rows;
  late LocalRowWriter writer;
  late FakeUserAuth auth;
  late FamilyScopeReader scope;
  late LocalDevicesRepository repository;

  setUp(() async {
    tables = LocalTables(InMemoryLocalStore());
    await tables.open();
    rows = LocalRowReader(tables);
    writer = LocalRowWriter(tables, LocalChangeFeed());
    auth = FakeUserAuth(session);
    scope = FamilyScopeReader(auth: () => auth, rows: () => rows);
    repository = LocalDevicesRepository(
      scope: () => scope,
      rows: () => rows,
      writer: () => writer,
    );

    // Seed family
    await writer.insert(TableName.families, {
      'id': 'f1',
      'name': 'Rivera',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    await writer.insert(TableName.familyMembers, {
      'id': 'm1',
      'family_id': 'f1',
      'user_id': 'u1',
      'role': 'parent',
      'status': 'active',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  });

  group('LocalDevicesRepository', () {
    test('pairedDevices returns empty list when no devices saved', () async {
      final Result<List<Device>> result = await repository.pairedDevices();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('createDevice inserts simulated device record in local store', () async {
      final Result<Device> created = await repository.createDevice(
        displayName: 'Pixel 8',
        childUserId: 'c1',
        platform: 'android',
        batteryLevel: 90,
      );
      expect(created.isOk, isTrue);
      final Device dev = created.valueOrNull!;
      expect(dev.displayName, 'Pixel 8');
      expect(dev.childUserId, 'c1');
      expect(dev.batteryLevel, 90);
      expect(dev.installationId, startsWith('sim-'));
      expect(dev.status, 'active');

      final List<Device> list = (await repository.pairedDevices()).valueOrNull!;
      expect(list.length, 1);
      expect(list.first.displayName, 'Pixel 8');
    });

    test('device reads a saved device record by id', () async {
      final Device created = (await repository.createDevice(
        displayName: 'Tablet',
        childUserId: 'c1',
      )).valueOrNull!;

      final Result<Device> read = await repository.device(created.id);
      expect(read.isOk, isTrue);
      expect(read.valueOrNull!.displayName, 'Tablet');
    });

    test('rename updates device display name locally', () async {
      final Device created = (await repository.createDevice(
        displayName: 'Old Name',
        childUserId: 'c1',
      )).valueOrNull!;

      final Result<void> renameResult = await repository.rename(
        deviceId: created.id,
        name: 'New Name',
      );
      expect(renameResult.isOk, isTrue);

      final Device updated = (await repository.device(created.id)).valueOrNull!;
      expect(updated.displayName, 'New Name');
    });

    test('assignChild updates child association locally', () async {
      final Device created = (await repository.createDevice(
        displayName: 'Phone',
        childUserId: 'c1',
      )).valueOrNull!;

      final Result<void> reassign = await repository.assignChild(
        deviceId: created.id,
        childUserId: 'c2',
      );
      expect(reassign.isOk, isTrue);

      final Device updated = (await repository.device(created.id)).valueOrNull!;
      expect(updated.childUserId, 'c2');
    });

    test('unlink revokes the device and records credential_revoked_at', () async {
      final Device created = (await repository.createDevice(
        displayName: 'Phone',
        childUserId: 'c1',
      )).valueOrNull!;

      final Result<void> unlinked = await repository.unlink(created.id);
      expect(unlinked.isOk, isTrue);

      final Device updated = (await repository.device(created.id)).valueOrNull!;
      expect(updated.status, 'revoked');
      expect(updated.credentialRevokedAt, isNotNull);
    });
  });
}
