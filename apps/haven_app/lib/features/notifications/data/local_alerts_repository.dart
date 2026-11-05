// ignore_for_file: prefer_initializing_formals

import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../child_devices/data/devices_repository.dart';
import '../../family/data/family_scope.dart';
import 'alerts_models.dart';
import 'alerts_repository.dart';

/// Offline-first alerts repository reading from and mutating [LocalTables].
final class LocalAlertsRepository implements AlertsRepository {
  LocalAlertsRepository({
    required FamilyScopeReader Function() scope,
    required RowReader Function() rows,
    required RowWriter Function() writer,
    required DevicesRepository Function() devices,
  })  : _scope = scope,
        _rows = rows,
        _writer = writer,
        _devices = devices;

  final FamilyScopeReader Function() _scope;
  final RowReader Function() _rows;
  final RowWriter Function() _writer;
  final DevicesRepository Function() _devices;

  factory LocalAlertsRepository.live() {
    final FamilyScopeReader reader = FamilyScopeReader(
      auth: () => HavenBackend.auth,
      rows: () => HavenBackend.rows,
    );
    return LocalAlertsRepository(
      scope: () => reader,
      rows: () => HavenBackend.rows,
      writer: () => HavenBackend.writer,
      devices: () => Get.find<DevicesRepository>(),
    );
  }

  @override
  Future<Result<AlertBoard?>> load() async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) {
      final HavenFailure why = scope.failureOrNull!;
      return FamilyScopeReader.isMissingFamily(why)
          ? const Ok<AlertBoard?>(null)
          : Err<AlertBoard?>(why);
    }

    final Result<List<Map<String, Object?>>> rows = await _rows().rows(
      TableName.safetyAlerts,
      eq: <String, Object?>{'family_id': mine.familyId},
      orderDesc: 'created_at',
      limit: AlertBoard.window,
    );
    final HavenFailure? readFailure = rows.failureOrNull;
    if (readFailure != null) return Err<AlertBoard?>(readFailure);

    final Result<List<Device>> owners = await _devices().pairedDevices();
    final List<Device>? named = owners.valueOrNull;

    final List<AlertLine> lines = rows.valueOrNull!.map((row) {
      final SafetyAlert alert = SafetyAlert.fromRow(row);
      final bool isDemo = LocalQueries.isDemoRow(row) || alert.id.startsWith('demo_');
      return AlertLine(
        alert,
        deviceName: named == null ? null : _nameOf(named, alert.deviceId),
        isDemo: isDemo,
      );
    }).toList(growable: false);

    return Ok<AlertBoard?>(
      AlertBoard(
        familyId: mine.familyId,
        lines: lines,
        ackGap: HavenAlertsRepository.ackGap,
        deliveryGap: HavenAlertsRepository.deliveryGap,
        deviceGap: null,
        isOffline: true,
      ),
    );
  }

  @override
  Future<Result<void>> markAsRead(String alertId, {String? userId}) async {
    return _writer().update(
      TableName.safetyAlerts,
      <String, Object?>{
        'acknowledged_at': DateTime.now().toUtc().toIso8601String(),
        'acknowledged_by': userId ?? 'parent',
      },
      eq: {'id': alertId},
    );
  }

  @override
  Future<Result<void>> markAsUnread(String alertId) async {
    return _writer().update(
      TableName.safetyAlerts,
      <String, Object?>{
        'acknowledged_at': null,
        'acknowledged_by': null,
      },
      eq: {'id': alertId},
    );
  }

  @override
  Future<Result<void>> deleteAlert(String alertId) async {
    return _writer().delete(
      TableName.safetyAlerts,
      eq: {'id': alertId},
    );
  }

  static String? _nameOf(List<Device> devices, String id) {
    if (id.isEmpty) return null;
    for (final Device device in devices) {
      if (device.id == id) {
        return device.displayName.isEmpty ? null : device.displayName;
      }
    }
    return null;
  }
}
