// ignore_for_file: prefer_initializing_formals

import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../child_devices/data/devices_repository.dart';
import '../../family/data/family_scope.dart';
import 'activity_models.dart';
import 'activity_repository.dart';

/// Offline-first activity repository reading from and logging to [LocalTables].
final class LocalActivityRepository implements ActivityRepository {
  LocalActivityRepository({
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

  factory LocalActivityRepository.live() {
    final FamilyScopeReader reader = FamilyScopeReader(
      auth: () => HavenBackend.auth,
      rows: () => HavenBackend.rows,
    );
    return LocalActivityRepository(
      scope: () => reader,
      rows: () => HavenBackend.rows,
      writer: () => HavenBackend.writer,
      devices: () => Get.find<DevicesRepository>(),
    );
  }

  @override
  Future<Result<UsageBoard?>> load({String? deviceId}) async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) {
      final HavenFailure why = scope.failureOrNull!;
      return FamilyScopeReader.isMissingFamily(why)
          ? const Ok<UsageBoard?>(null)
          : Err<UsageBoard?>(why);
    }

    final usageFilter = <String, Object?>{
      'family_id': mine.familyId,
      if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
    };

    final usageResult = await _rows().rows(
      TableName.usageDaily,
      eq: usageFilter,
      orderDesc: 'day',
      limit: UsageBoard.window,
    );
    if (usageResult.isErr) return Err<UsageBoard?>(usageResult.failureOrNull!);

    final Result<List<Device>> owners = await _devices().pairedDevices();
    final List<Device>? named = owners.valueOrNull;

    final List<UsageLine> lines = usageResult.valueOrNull!.map((row) {
      final UsageDaily usage = UsageDaily.fromRow(row);
      final bool isDemo = LocalQueries.isDemoRow(row) || usage.id.startsWith('demo_');
      return UsageLine(
        usage,
        deviceName: named == null ? null : _nameOf(named, usage.deviceId),
        isDemo: isDemo,
      );
    }).toList(growable: false);

    // Build timeline events from usage, alerts, and location events
    final List<TimelineActivityEvent> events = [];

    for (final line in lines) {
      events.add(TimelineActivityEvent(
        id: line.usage.id,
        title: line.appLabel,
        subtitle: '${line.duration} — ${line.whose}',
        timestamp: line.usage.lastUsedAt ?? line.usage.day ?? DateTime.now(),
        category: 'app_usage',
        deviceName: line.whose,
        isDemo: line.isDemo,
      ));
    }

    final alertsResult = await _rows().rows(
      TableName.safetyAlerts,
      eq: usageFilter,
      orderDesc: 'created_at',
      limit: 20,
    );
    if (alertsResult.isOk) {
      for (final row in alertsResult.valueOrNull!) {
        final alert = SafetyAlert.fromRow(row);
        final bool isDemo = LocalQueries.isDemoRow(row) || alert.id.startsWith('demo_');
        final alertType = alert.type ?? 'unknown';
        final cat = alertType.contains('geofence')
            ? 'geofence'
            : (alertType.contains('battery') ? 'battery' : 'alert');
        events.add(TimelineActivityEvent(
          id: alert.id,
          title: alert.message,
          subtitle: alertType,
          timestamp: alert.createdAt,
          category: cat,
          deviceName: named == null ? null : _nameOf(named, alert.deviceId),
          isDemo: isDemo,
        ));
      }
    }

    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Ok<UsageBoard?>(
      UsageBoard(
        familyId: mine.familyId,
        deviceId: deviceId,
        lines: lines,
        events: events,
        deviceGap: null,
        isOffline: true,
      ),
    );
  }

  @override
  Future<Result<void>> logActivityEvent({
    required String familyId,
    required String deviceId,
    required String category,
    required String title,
    required String subtitle,
    Map<String, Object?>? payload,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    if (category == 'geofence') {
      return _writer().insert(TableName.locationEvents, <String, Object?>{
        'id': 'loc_${DateTime.now().millisecondsSinceEpoch}',
        'family_id': familyId,
        'device_id': deviceId,
        'source': subtitle,
        'created_at': now,
      });
    }
    return _writer().insert(TableName.safetyAlerts, <String, Object?>{
      'id': 'alert_${DateTime.now().millisecondsSinceEpoch}',
      'family_id': familyId,
      'device_id': deviceId,
      'type': category,
      'severity': 'info',
      'message': title,
      'payload': payload ?? <String, Object?>{'subtitle': subtitle},
      'created_at': now,
    });
  }

  static String? _nameOf(List<Device> devices, String id) {
    for (final Device device in devices) {
      if (device.id == id) {
        return device.displayName.isEmpty ? null : device.displayName;
      }
    }
    return null;
  }
}
