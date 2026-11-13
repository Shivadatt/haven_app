import 'package:haven_core/haven_core.dart';

import 'backend_endpoints.dart';
import 'demo_data_records.dart';
import 'local_queries.dart';
import 'local_tables.dart';

export 'demo_data_records.dart';

/// Deterministic demo data suite for offline-first testing and evaluation.
///
/// Every row inserted by this suite is flagged with `is_demo: true`.
/// Calling [clearDemoData] removes exclusively these demo-flagged rows via
/// [LocalTables.clearDemoData], guaranteeing that user records remain untouched.
final class DemoDataSuite {
  const DemoDataSuite._();

  static const String demoFamilyId = DemoDataRecords.demoFamilyId;
  static const String demoFamilyName = DemoDataRecords.demoFamilyName;
  static const String demoParentUserId = DemoDataRecords.demoParentUserId;
  static const String demoParentName = DemoDataRecords.demoParentName;
  static const String demoChildUserId = DemoDataRecords.demoChildUserId;
  static const String demoChildName = DemoDataRecords.demoChildName;
  static const String demoDeviceId = DemoDataRecords.demoDeviceId;
  static const String demoDeviceName = DemoDataRecords.demoDeviceName;
  static const String demoDeviceModel = DemoDataRecords.demoDeviceModel;
  static const String demoZoneHomeId = DemoDataRecords.demoZoneHomeId;
  static const String demoZoneSchoolId = DemoDataRecords.demoZoneSchoolId;
  static const String demoPolicyId = DemoDataRecords.demoPolicyId;

  /// Seeds a complete deterministic demo family hierarchy into [tables].
  static Future<Result<void>> loadDemoData(
    LocalTables tables, {
    String? parentUserId,
  }) async {
    final opened = await tables.open();
    if (opened.isErr) return opened;

    await tables.clearDemoData();

    final actualParentId = parentUserId?.isNotEmpty == true
        ? parentUserId!
        : demoParentUserId;

    return DemoDataRecords.seed(tables, parentId: actualParentId);
  }

  /// Removes demo data without touching user records.
  static Future<Result<void>> clearDemoData(LocalTables tables) =>
      tables.clearDemoData();

  /// Returns whether demo data is currently loaded.
  static Future<Result<bool>> hasDemoData(LocalTables tables) async {
    final rowsRes = await tables.rows(TableName.families);
    if (rowsRes.isErr) return Err<bool>(rowsRes.failureOrNull!);
    final demoFound = rowsRes.valueOrNull!.any(LocalQueries.isDemoRow);
    return Ok<bool>(demoFound);
  }
}
