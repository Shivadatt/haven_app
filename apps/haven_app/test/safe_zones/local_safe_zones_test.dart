import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/family/data/family_scope.dart';
import 'package:haven_app/features/safe_zones/data/local_zones_repository.dart';
import 'package:haven_app/features/safe_zones/data/safe_zone_rules.dart';
import 'package:haven_app/features/safe_zones/data/zones_models.dart';

import '../support/data_fakes.dart';
import '../support/fakes.dart';

void main() {
  late FakeRowWriter writer;
  late FakeRowReader reader;
  late LocalSafeZonesRepository repo;

  final auth = FakeUserAuth(
    const AuthSession(
      userId: 'u_parent',
      email: 'parent@haven.test',
      accessToken: 'token',
    ),
  );

  final familyMembers = [
    {
      'id': 'm1',
      'family_id': 'f1',
      'user_id': 'u_parent',
      'role': 'parent',
      'status': 'active',
      'created_at': '2026-01-01T00:00:00Z',
    },
  ];

  setUp(() {
    writer = FakeRowWriter();
    reader = FakeRowReader({
      TableName.familyMembers: familyMembers,
      TableName.safeZones: <Map<String, Object?>>[],
    });
    final scope = FamilyScopeReader(auth: () => auth, rows: () => reader);
    repo = LocalSafeZonesRepository(
      scope: () => scope,
      rows: () => reader,
      writer: () => writer,
    );
  });

  group('LocalSafeZonesRepository - Create Safe Zone (Converts Refusal #12)', () {
    test('creates safe zone with valid name, coordinates and radius', () async {
      final draft = ZoneDraft(
        name: 'School',
        lat: '37.7749',
        lng: '-122.4194',
        radiusM: '250',
        active: true,
      );

      final res = await repo.create(draft: draft);
      expect(res.isOk, isTrue);
      expect(writer.writtenTables, contains(TableName.safeZones));
      final payload = writer.lastPayload!;
      expect(payload['family_id'], 'f1');
      expect(payload['name'], 'School');
      expect(payload['lat'], 37.7749);
      expect(payload['lng'], -122.4194);
      expect(payload['radius_m'], 250.0);
      expect(payload['active'], isTrue);
    });

    test('enforces name length constraints (1..60 chars)', () {
      expect(SafeZoneRules.name(''), isNotNull);
      expect(SafeZoneRules.name('   '), isNotNull);
      expect(SafeZoneRules.name('A' * 61), isNotNull);
      expect(SafeZoneRules.name('Valid Safe Zone'), isNull);
    });

    test('enforces radius constraints (50m..5000m)', () {
      expect(SafeZoneRules.radius('49'), isNotNull);
      expect(SafeZoneRules.radius('5001'), isNotNull);
      expect(SafeZoneRules.radius('abc'), isNotNull);
      expect(SafeZoneRules.radius('50'), isNull);
      expect(SafeZoneRules.radius('5000'), isNull);
      expect(SafeZoneRules.radius('250'), isNull);
    });

    test('enforces latitude (-90..90) and longitude (-180..180)', () {
      expect(SafeZoneRules.lat('91'), isNotNull);
      expect(SafeZoneRules.lat('-91'), isNotNull);
      expect(SafeZoneRules.lat('37.7749'), isNull);
      expect(SafeZoneRules.lng('181'), isNotNull);
      expect(SafeZoneRules.lng('-181'), isNotNull);
      expect(SafeZoneRules.lng('-122.4194'), isNull);
    });

    test('enforces name uniqueness within the family', () async {
      reader.tables[TableName.safeZones] = [
        {
          'id': 'z1',
          'family_id': 'f1',
          'name': 'Home',
          'lat': 37.77,
          'lng': -122.41,
          'radius_m': 100.0,
          'active': true,
          'created_at': '2026-01-01T00:00:00Z',
        },
      ];

      final duplicateDraft = ZoneDraft(
        name: 'home',
        lat: '37.80',
        lng: '-122.40',
        radiusM: '150',
        active: true,
      );

      final res = await repo.create(draft: duplicateDraft);
      expect(res.isErr, isTrue);
      expect(res.failureOrNull?.message, contains('already exists'));
    });
  });

  group('LocalSafeZonesRepository - Read, Edit, Delete', () {
    test('load returns ZoneBoard with isOffline true', () async {
      reader.tables[TableName.safeZones] = [
        {
          'id': 'z1',
          'family_id': 'f1',
          'name': 'Park',
          'lat': 37.77,
          'lng': -122.41,
          'radius_m': 300.0,
          'active': true,
          'created_at': '2026-01-01T00:00:00Z',
        },
      ];

      final res = await repo.load();
      expect(res.isOk, isTrue);
      final board = res.valueOrNull!;
      expect(board.isOffline, isTrue);
      expect(board.zones.length, 1);
      expect(board.zones.first.name, 'Park');
    });

    test('save updates existing zone and enforces unique name', () async {
      reader.tables[TableName.safeZones] = [
        {
          'id': 'z1',
          'family_id': 'f1',
          'name': 'Home',
          'lat': 37.77,
          'lng': -122.41,
          'radius_m': 100.0,
          'active': true,
          'created_at': '2026-01-01T00:00:00Z',
        },
        {
          'id': 'z2',
          'family_id': 'f1',
          'name': 'School',
          'lat': 37.78,
          'lng': -122.42,
          'radius_m': 200.0,
          'active': true,
          'created_at': '2026-01-01T00:00:00Z',
        },
      ];

      final clashDraft = ZoneDraft(
        name: 'Home',
        lat: '37.78',
        lng: '-122.42',
        radiusM: '200',
        active: true,
      );
      final clashRes = await repo.save(zoneId: 'z2', draft: clashDraft);
      expect(clashRes.isErr, isTrue);

      final validDraft = ZoneDraft(
        name: 'Home',
        lat: '37.775',
        lng: '-122.415',
        radiusM: '150',
        active: true,
      );
      final saveRes = await repo.save(zoneId: 'z1', draft: validDraft);
      expect(saveRes.isOk, isTrue);
    });

    test('remove deletes the zone by id', () async {
      final res = await repo.remove(zoneId: 'z1');
      expect(res.isOk, isTrue);
      expect(writer.writtenTables, contains(TableName.safeZones));
      expect(writer.matchers.last['id'], 'z1');
    });
  });
}
