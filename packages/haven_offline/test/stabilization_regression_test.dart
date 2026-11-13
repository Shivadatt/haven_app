import 'package:flutter_test/flutter_test.dart';
import 'package:haven_offline/haven_offline.dart';
import 'package:haven_core/haven_core.dart';

void main() {
  late LocalTables tables;
  late InMemoryLocalStore store;

  setUp(() async {
    store = InMemoryLocalStore();
    tables = LocalTables(store);
    await tables.open();
  });

  group('Stabilization: LocalTables.update forward collision validation', () {
    test('updating the first row to conflict with a subsequent row is refused', () async {
      await tables.insert(TableName.families, {'id': 'fam_1', 'name': 'Smith'});
      await tables.insert(TableName.safeZones, {
        'id': 'z1',
        'family_id': 'fam_1',
        'name': 'Home',
        'lat': 10.0,
        'lng': 20.0,
        'radius_m': 100,
      });
      await tables.insert(TableName.safeZones, {
        'id': 'z2',
        'family_id': 'fam_1',
        'name': 'School',
        'lat': 10.1,
        'lng': 20.1,
        'radius_m': 150,
      });

      // Updating z1 (the first row) to 'School' must fail because z2 already has 'School'
      final result = await tables.update(
        TableName.safeZones,
        {'name': 'School'},
        eq: {'id': 'z1'},
      );
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<BackendFailure>());
      expect(result.failureOrNull?.detail, contains('safe_zones.family_id.name'));

      // Ensure z1 was not modified
      final z1 = await tables.first(TableName.safeZones, eq: {'id': 'z1'});
      expect(z1.valueOrNull?['name'], 'Home');
    });

    test('updating row to its own current value succeeds without self-collision', () async {
      await tables.insert(TableName.families, {'id': 'fam_1', 'name': 'Smith'});
      await tables.insert(TableName.safeZones, {
        'id': 'z1',
        'family_id': 'fam_1',
        'name': 'Home',
        'lat': 10.0,
        'lng': 20.0,
        'radius_m': 100,
      });

      final result = await tables.update(
        TableName.safeZones,
        {'radius_m': 200},
        eq: {'id': 'z1'},
      );
      expect(result.isOk, isTrue);
      final z1 = await tables.first(TableName.safeZones, eq: {'id': 'z1'});
      expect(z1.valueOrNull?['radius_m'], 200);
    });
  });

  group('Stabilization: familyMembers unique constraint', () {
    test('inserting the same user into the same family twice is refused', () async {
      await tables.insert(TableName.families, {'id': 'fam_1', 'name': 'Smith'});
      await tables.insert(TableName.profiles, {
        'id': 'u1',
        'display_name': 'Parent User',
        'role': 'parent',
      });

      final first = await tables.insert(TableName.familyMembers, {
        'id': 'fm_1',
        'family_id': 'fam_1',
        'user_id': 'u1',
        'role': 'parent',
      });
      expect(first.isOk, isTrue);

      final duplicate = await tables.insert(TableName.familyMembers, {
        'id': 'fm_2',
        'family_id': 'fam_1',
        'user_id': 'u1',
        'role': 'parent',
      });
      expect(duplicate.isErr, isTrue);
      expect(duplicate.failureOrNull, isA<BackendFailure>());
      expect(duplicate.failureOrNull?.detail, contains('family_members.family_id.user_id'));
    });
  });

  group('Stabilization: demo data seeding with active user profile', () {
    test('seeding demo data preserves user profile and does not mark it as demo', () async {
      const realUserId = 'real_parent_123';
      await tables.insert(TableName.profiles, {
        'id': realUserId,
        'display_name': 'Real Parent',
        'role': 'parent',
        'created_at': '2026-11-01T00:00:00Z',
      });

      // Load demo data under the real parent's ID
      final loadRes = await DemoDataSuite.loadDemoData(
        tables,
        parentUserId: realUserId,
      );
      expect(loadRes.isOk, isTrue);

      // Verify real profile exists and has NO is_demo flag
      final profile = await tables.first(TableName.profiles, eq: {'id': realUserId});
      expect(profile.isOk, isTrue);
      expect(profile.valueOrNull?['display_name'], 'Real Parent');
      expect(profile.valueOrNull?['is_demo'], isNull);

      // Verify demo items exist
      final fams = await tables.rows(TableName.families);
      expect(fams.valueOrNull!.any((f) => f['id'] == DemoDataSuite.demoFamilyId), isTrue);

      // Clear demo data
      final clearRes = await DemoDataSuite.clearDemoData(tables);
      expect(clearRes.isOk, isTrue);

      // Real user profile MUST still exist!
      final profileAfter = await tables.first(TableName.profiles, eq: {'id': realUserId});
      expect(profileAfter.isOk, isTrue);
      expect(profileAfter.valueOrNull, isNotNull);
      expect(profileAfter.valueOrNull?['id'], realUserId);

      // Demo family must be gone
      final demoFam = await tables.first(
        TableName.families,
        eq: {'id': DemoDataSuite.demoFamilyId},
      );
      expect(demoFam.valueOrNull, isNull);
    });
  });
}

