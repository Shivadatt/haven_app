import 'package:haven_core/haven_core.dart';

import 'backend_endpoints.dart';
import 'local_tables.dart';

/// Predefined deterministic demo records for [DemoDataSuite].
final class DemoDataRecords {
  const DemoDataRecords._();

  static const String demoFamilyId = 'demo_family_haven';
  static const String demoFamilyName = 'Rivera Family (Demo)';
  static const String demoParentUserId = 'demo_parent_alex';
  static const String demoParentName = 'Alex Rivera (Demo)';
  static const String demoChildUserId = 'demo_child_ivy';
  static const String demoChildName = 'Ivy Rivera (Demo)';
  static const String demoDeviceId = 'demo_device_pixel8';
  static const String demoDeviceName = "Ivy's Pixel 8 (Simulated)";
  static const String demoDeviceModel = 'Pixel 8';
  static const String demoZoneHomeId = 'demo_zone_home';
  static const String demoZoneSchoolId = 'demo_zone_school';
  static const String demoPolicyId = 'demo_policy_1';

  static String _now() => DateTime.now().toUtc().toIso8601String();
  static String _minutesAgo(int m) =>
      DateTime.now().subtract(Duration(minutes: m)).toUtc().toIso8601String();
  static String _today() => DateTime.now().toIso8601String().substring(0, 10);

  /// Inserts all demo records across families, profiles, devices, zones, policies, alerts, usage, locations.
  static Future<Result<void>> seed(
    LocalTables tables, {
    required String parentId,
  }) async {
    final famRes = await tables.insert(TableName.families, <String, Object?>{
      'id': demoFamilyId,
      'name': demoFamilyName,
      'created_at': _now(),
      'is_demo': true,
    });
    if (famRes.isErr) return famRes;

    if (parentId == demoParentUserId) {
      await tables.insert(TableName.profiles, <String, Object?>{
        'id': demoParentUserId,
        'display_name': demoParentName,
        'role': 'parent',
        'created_at': _now(),
        'is_demo': true,
      });
    }
    await tables.insert(TableName.profiles, <String, Object?>{
      'id': demoChildUserId,
      'display_name': demoChildName,
      'role': 'child',
      'created_at': _now(),
      'is_demo': true,
    });

    await tables.insert(TableName.familyMembers, <String, Object?>{
      'id': 'demo_fm_parent',
      'family_id': demoFamilyId,
      'user_id': parentId,
      'role': 'parent',
      'joined_at': _now(),
      'is_demo': true,
    });
    await tables.insert(TableName.familyMembers, <String, Object?>{
      'id': 'demo_fm_child',
      'family_id': demoFamilyId,
      'user_id': demoChildUserId,
      'role': 'child',
      'joined_at': _now(),
      'is_demo': true,
    });

    await tables.insert(TableName.devices, <String, Object?>{
      'id': demoDeviceId,
      'family_id': demoFamilyId,
      'child_user_id': demoChildUserId,
      'name': "Ivy's Pixel 8",
      'display_name': demoDeviceName,
      'platform': 'android',
      'model': demoDeviceModel,
      'status': 'active',
      'battery_level': 85,
      'created_at': _now(),
      'is_demo': true,
    });

    await tables.insert(TableName.safeZones, <String, Object?>{
      'id': demoZoneHomeId,
      'family_id': demoFamilyId,
      'name': 'Home (Safe Zone)',
      'lat': 37.7749,
      'lng': -122.4194,
      'radius_m': 200,
      'active': true,
      'created_at': _now(),
      'is_demo': true,
    });
    await tables.insert(TableName.safeZones, <String, Object?>{
      'id': demoZoneSchoolId,
      'family_id': demoFamilyId,
      'name': 'School (Safe Zone)',
      'lat': 37.7849,
      'lng': -122.4094,
      'radius_m': 300,
      'active': true,
      'created_at': _now(),
      'is_demo': true,
    });

    await tables.insert(TableName.devicePolicies, <String, Object?>{
      'id': demoPolicyId,
      'family_id': demoFamilyId,
      'device_id': demoDeviceId,
      'version': 1,
      'status': 'active',
      'created_at': _now(),
      'is_demo': true,
    });

    await tables.insert(TableName.safetyAlerts, <String, Object?>{
      'id': 'demo_alert_geofence',
      'family_id': demoFamilyId,
      'device_id': demoDeviceId,
      'type': 'geofence_exit',
      'severity': 'warning',
      'message': 'Ivy exited Home safe zone',
      'payload': <String, Object?>{'zone_name': 'Home'},
      'created_at': _minutesAgo(15),
      'is_demo': true,
    });
    await tables.insert(TableName.safetyAlerts, <String, Object?>{
      'id': 'demo_alert_battery',
      'family_id': demoFamilyId,
      'device_id': demoDeviceId,
      'type': 'battery_low',
      'severity': 'info',
      'message': "Ivy's Pixel battery reached 14%",
      'payload': <String, Object?>{'level': 14},
      'created_at': _minutesAgo(45),
      'is_demo': true,
    });

    await tables.insert(TableName.usageDaily, <String, Object?>{
      'id': 'demo_usage_khan',
      'family_id': demoFamilyId,
      'device_id': demoDeviceId,
      'day': _today(),
      'package_name': 'org.khanacademy.android',
      'app_label': 'Khan Academy',
      'total_ms': 2700000,
      'last_used_at': _minutesAgo(30),
      'is_demo': true,
    });
    await tables.insert(TableName.usageDaily, <String, Object?>{
      'id': 'demo_usage_duo',
      'family_id': demoFamilyId,
      'device_id': demoDeviceId,
      'day': _today(),
      'package_name': 'com.duolingo',
      'app_label': 'Duolingo',
      'total_ms': 1800000,
      'last_used_at': _minutesAgo(60),
      'is_demo': true,
    });

    await tables.insert(TableName.locationEvents, <String, Object?>{
      'id': 'demo_loc_1',
      'family_id': demoFamilyId,
      'device_id': demoDeviceId,
      'lat': 37.7749,
      'lng': -122.4194,
      'source': 'gps',
      'created_at': _minutesAgo(20),
      'is_demo': true,
    });
    await tables.insert(TableName.locationEvents, <String, Object?>{
      'id': 'demo_loc_2',
      'family_id': demoFamilyId,
      'device_id': demoDeviceId,
      'lat': 37.7770,
      'lng': -122.4210,
      'source': 'geofence_exit',
      'created_at': _minutesAgo(15),
      'is_demo': true,
    });

    return okVoid();
  }
}
