import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/child_devices/data/devices_repository.dart';
import 'package:haven_app/features/family/data/family_scope.dart';
import 'package:haven_app/features/notifications/data/local_alerts_repository.dart';

import '../child_devices/fakes.dart';
import '../support/data_fakes.dart';
import '../support/fakes.dart';

void main() {
  late FakeRowWriter writer;
  late FakeRowReader reader;
  late LocalAlertsRepository repo;

  final auth = FakeUserAuth(
    const AuthSession(
      userId: 'u1',
      email: 'parent@haven.test',
      accessToken: 'token',
    ),
  );

  final familyMembers = [
    {
      'id': 'm1',
      'family_id': 'f1',
      'user_id': 'u1',
      'role': 'parent',
      'status': 'active',
      'created_at': '2026-01-01T00:00:00Z',
    },
  ];

  setUp(() {
    writer = FakeRowWriter();
    reader = FakeRowReader({
      TableName.familyMembers: familyMembers,
      TableName.safetyAlerts: [
        {
          'id': 'a1',
          'family_id': 'f1',
          'device_id': 'd1',
          'type': 'geofence_exit',
          'severity': 'warning',
          'message': 'Left Safe Zone',
          'payload': <String, Object?>{},
          'created_at': '2026-11-01T12:00:00Z',
          'is_demo': true,
        },
      ],
    });
    final scope = FamilyScopeReader(auth: () => auth, rows: () => reader);
    final DevicesRepository devices = FakeDevicesRepository(
      devices: [fakeDevice('d1', name: "Ivy's Phone")],
    );
    repo = LocalAlertsRepository(
      scope: () => scope,
      rows: () => reader,
      writer: () => writer,
      devices: () => devices,
    );
  });

  group('LocalAlertsRepository', () {
    test('load returns AlertBoard with canManage true and lines mapped', () async {
      final res = await repo.load();
      expect(res.isOk, isTrue);
      final board = res.valueOrNull!;
      expect(board.isOffline, isTrue);
      expect(board.canManage, isTrue);
      expect(board.lines.length, 1);
      expect(board.lines.first.said, 'Left Safe Zone');
      expect(board.lines.first.isDemo, isTrue);
      expect(board.lines.first.whose, "Ivy's Phone");
    });

    test('markAsRead updates acknowledged_at and acknowledged_by', () async {
      final res = await repo.markAsRead('a1', userId: 'u1');
      expect(res.isOk, isTrue);
      expect(writer.writtenTables, contains(TableName.safetyAlerts));
      expect(writer.lastPayload!['acknowledged_by'], 'u1');
      expect(writer.lastPayload!['acknowledged_at'], isNotNull);
      expect(writer.matchers.last['id'], 'a1');
    });

    test('markAsUnread clears acknowledged_at and acknowledged_by', () async {
      final res = await repo.markAsUnread('a1');
      expect(res.isOk, isTrue);
      expect(writer.writtenTables, contains(TableName.safetyAlerts));
      expect(writer.lastPayload!['acknowledged_by'], isNull);
      expect(writer.lastPayload!['acknowledged_at'], isNull);
      expect(writer.matchers.last['id'], 'a1');
    });

    test('deleteAlert removes the alert row', () async {
      final res = await repo.deleteAlert('a1');
      expect(res.isOk, isTrue);
      expect(writer.writtenTables, contains(TableName.safetyAlerts));
      expect(writer.matchers.last['id'], 'a1');
    });
  });
}
