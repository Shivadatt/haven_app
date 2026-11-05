import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/child_devices/data/devices_repository.dart';
import 'package:haven_app/features/device_activity/data/local_activity_repository.dart';
import 'package:haven_app/features/family/data/family_scope.dart';

import '../child_devices/fakes.dart';
import '../support/data_fakes.dart';
import '../support/fakes.dart';

void main() {
  late FakeRowWriter writer;
  late FakeRowReader reader;
  late LocalActivityRepository repo;

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
      TableName.usageDaily: [
        {
          'id': 'u1',
          'family_id': 'f1',
          'device_id': 'd1',
          'day': '2026-11-01',
          'package_name': 'com.test.app',
          'app_label': 'Test App',
          'total_ms': 3600000,
          'is_demo': true,
        },
      ],
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
    repo = LocalActivityRepository(
      scope: () => scope,
      rows: () => reader,
      writer: () => writer,
      devices: () => devices,
    );
  });

  group('LocalActivityRepository', () {
    test('load returns UsageBoard with lines and timeline events', () async {
      final res = await repo.load();
      expect(res.isOk, isTrue);
      final board = res.valueOrNull!;
      expect(board.isOffline, isTrue);
      expect(board.hasLines, isTrue);
      expect(board.lines.first.appLabel, 'Test App');
      expect(board.lines.first.isDemo, isTrue);
      expect(board.lines.first.whose, "Ivy's Phone");

      expect(board.hasEvents, isTrue);
      expect(board.events.length, 2);
      expect(board.events.any((e) => e.category == 'geofence'), isTrue);
      expect(board.events.any((e) => e.category == 'app_usage'), isTrue);
    });

    test('logActivityEvent records geofence location event', () async {
      final res = await repo.logActivityEvent(
        familyId: 'f1',
        deviceId: 'd1',
        category: 'geofence',
        title: 'Geofence Event',
        subtitle: 'safe_zone_exit',
      );
      expect(res.isOk, isTrue);
      expect(writer.writtenTables, contains(TableName.locationEvents));
      expect(writer.lastPayload!['source'], 'safe_zone_exit');
    });

    test('logActivityEvent records safety alert event', () async {
      final res = await repo.logActivityEvent(
        familyId: 'f1',
        deviceId: 'd1',
        category: 'battery',
        title: 'Battery Low',
        subtitle: '15%',
      );
      expect(res.isOk, isTrue);
      expect(writer.writtenTables, contains(TableName.safetyAlerts));
      expect(writer.lastPayload!['type'], 'battery');
    });
  });
}
