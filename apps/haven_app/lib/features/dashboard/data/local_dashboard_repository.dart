// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../child_devices/data/devices_repository.dart';
import '../../family/data/family_models.dart';
import '../../family/data/family_repository.dart';
import '../../safe_zones/data/zones_repository.dart';
import 'dashboard_activity_item.dart';
import 'dashboard_repository.dart';

/// Offline-first local dashboard repository that reads real persisted data from [LocalTables].
final class LocalDashboardRepository implements DashboardRepository {
  LocalDashboardRepository({
    required FamilyRepository family,
    required RowReader Function() rows,
    required DevicesRepository Function() devices,
    required SafeZonesRepository Function() zones,
  })  : _family = family,
        _rows = rows,
        _devices = devices,
        _zones = zones;

  final FamilyRepository _family;
  final RowReader Function() _rows;
  final DevicesRepository Function() _devices;
  final SafeZonesRepository Function() _zones;

  factory LocalDashboardRepository.live({
    required FamilyRepository family,
    required DevicesRepository Function() devices,
    required SafeZonesRepository Function() zones,
  }) =>
      LocalDashboardRepository(
        family: family,
        rows: () => HavenBackend.rows,
        devices: devices,
        zones: zones,
      );

  @override
  Future<Result<DashboardData>> load() async {
    final Result<FamilyBundle?> bundle = await _family.load();
    final FamilyBundle? value = bundle.valueOrNull;
    if (value == null) {
      final HavenFailure? why = bundle.failureOrNull;
      if (why != null) return Err<DashboardData>(why);
      return const Ok<DashboardData>(
        DashboardData(family: null, alerts: <SafetyAlert>[]),
      );
    }

    final familyId = value.family.id;

    // 1. Alerts
    final alertsRes = await _rows().rows(
      TableName.safetyAlerts,
      eq: {'family_id': familyId},
      orderDesc: 'created_at',
      limit: DashboardData.alertWindow,
    );
    final List<SafetyAlert> alerts = alertsRes.valueOrNull != null
        ? alertsRes.valueOrNull!.map(SafetyAlert.fromRow).toList()
        : <SafetyAlert>[];

    // 2. Devices
    final devsRes = await _devices().pairedDevices();
    final List<Device> devices = devsRes.valueOrNull ?? <Device>[];

    // 3. Safe Zones
    final zonesRes = await _zones().load();
    final List<SafeZone> safeZones =
        zonesRes.valueOrNull?.zones ?? <SafeZone>[];

    // 4. Policies
    final polRes = await _rows().rows(
      TableName.devicePolicies,
      eq: {'family_id': familyId},
    );
    final activePolicies = polRes.valueOrNull
            ?.where((r) => r['status'] == 'active')
            .length ??
        0;

    // 5. Recent Activities
    final activities = await _loadRecentActivities(familyId, alerts);

    final isDemo = value.family.name.contains('Demo') ||
        devices.any((d) =>
            d.displayName.contains('Simulated') || d.id.startsWith('demo_'));

    return Ok<DashboardData>(
      DashboardData(
        family: value,
        alerts: alerts,
        devices: devices,
        safeZones: safeZones,
        activePoliciesCount: activePolicies,
        recentActivities: activities,
        isDemo: isDemo,
      ),
    );
  }

  Future<List<DashboardActivityItem>> _loadRecentActivities(
    String familyId,
    List<SafetyAlert> alerts,
  ) async {
    final items = <DashboardActivityItem>[];

    for (final a in alerts.take(3)) {
      items.add(DashboardActivityItem(
        id: a.id,
        title: a.message,
        detail: a.alertType?.label ?? 'Safety alert',
        timeAgo: _formatTime(a.createdAt),
        icon: Icons.notifications_active_rounded,
        isDemo: a.id.startsWith('demo_'),
      ));
    }

    final usageRes = await _rows().rows(
      TableName.usageDaily,
      eq: {'family_id': familyId},
      orderDesc: 'day',
      limit: 3,
    );
    for (final u in usageRes.valueOrNull ?? <Map<String, Object?>>[]) {
      final pkg = u['package_name']?.toString() ?? 'App';
      final sec = (u['total_seconds'] as num?)?.toInt() ?? 0;
      final mins = sec ~/ 60;
      items.add(DashboardActivityItem(
        id: u['id']?.toString() ?? 'usage',
        title: '$pkg used ($mins min)',
        detail: 'Reported app usage',
        timeAgo: u['day']?.toString() ?? 'today',
        icon: Icons.apps_rounded,
        isDemo: u['is_demo'] == true,
      ));
    }

    final locRes = await _rows().rows(
      TableName.locationEvents,
      eq: {'family_id': familyId},
      orderDesc: 'created_at',
      limit: 3,
    );
    for (final l in locRes.valueOrNull ?? <Map<String, Object?>>[]) {
      final src = l['source']?.toString() ?? 'location';
      items.add(DashboardActivityItem(
        id: l['id']?.toString() ?? 'loc',
        title: 'Location reported ($src)',
        detail: 'Device location update',
        timeAgo: 'recently',
        icon: Icons.place_rounded,
        isDemo: l['is_demo'] == true,
      ));
    }

    return items.take(5).toList();
  }

  static String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Future<Result<void>> pairedDevices() async => okVoid();
}
