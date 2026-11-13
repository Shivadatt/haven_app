import 'package:flutter_test/flutter_test.dart';
import 'package:haven_offline/haven_offline.dart';

void main() {
  late LocalTables tables;
  late InMemoryLocalStore store;

  setUp(() {
    store = InMemoryLocalStore();
    tables = LocalTables(store);
  });

  group('DemoDataSuite', () {
    test('loadDemoData inserts valid deterministic rows respecting constraints', () async {
      final res = await DemoDataSuite.loadDemoData(tables);
      expect(res.isOk, isTrue);

      final families = (await tables.rows(TableName.families)).valueOrNull!;
      expect(families.length, 1);
      expect(families.first['id'], DemoDataSuite.demoFamilyId);
      expect(families.first['is_demo'], isTrue);

      final devices = (await tables.rows(TableName.devices)).valueOrNull!;
      expect(devices.length, 1);
      expect(devices.first['id'], DemoDataSuite.demoDeviceId);
      expect(devices.first['is_demo'], isTrue);

      final zones = (await tables.rows(TableName.safeZones)).valueOrNull!;
      expect(zones.length, 2);

      final alerts = (await tables.rows(TableName.safetyAlerts)).valueOrNull!;
      expect(alerts.length, 2);

      final hasDemo = (await DemoDataSuite.hasDemoData(tables)).valueOrNull!;
      expect(hasDemo, isTrue);
    });

    test('clearDemoData removes only demo records and preserves user records', () async {
      // 1. Insert user-owned records
      await tables.insert(TableName.families, <String, Object?>{
        'id': 'real_family',
        'name': 'Real Family',
      });
      await tables.insert(TableName.profiles, <String, Object?>{
        'id': 'real_user',
        'display_name': 'Real Parent',
        'role': 'parent',
      });
      await tables.insert(TableName.familyMembers, <String, Object?>{
        'id': 'real_fm',
        'family_id': 'real_family',
        'user_id': 'real_user',
        'role': 'parent',
      });

      // 2. Load demo data
      await DemoDataSuite.loadDemoData(tables);
      final famsWithDemo = (await tables.rows(TableName.families)).valueOrNull!;
      expect(famsWithDemo.length, 2);

      // 3. Clear demo data
      final clearRes = await DemoDataSuite.clearDemoData(tables);
      expect(clearRes.isOk, isTrue);

      final famsKept = (await tables.rows(TableName.families)).valueOrNull!;
      expect(famsKept.length, 1);
      expect(famsKept.first['id'], 'real_family');

      final hasDemo = (await DemoDataSuite.hasDemoData(tables)).valueOrNull!;
      expect(hasDemo, isFalse);
    });
  });
}
