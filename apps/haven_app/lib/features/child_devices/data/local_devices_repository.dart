import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../family/data/family_scope.dart';
import 'devices_repository.dart';

/// Offline devices repository over LocalTables.
final class LocalDevicesRepository implements DevicesRepository {
  LocalDevicesRepository({
    required FamilyScopeReader Function() scope,
    required RowReader Function() rows,
    required RowWriter Function() writer,
  }) : _scope = scope,
       _rows = rows,
       _writer = writer;

  final FamilyScopeReader Function() _scope;
  final RowReader Function() _rows;
  final RowWriter Function() _writer;

  factory LocalDevicesRepository.live() => LocalDevicesRepository(
    scope: () => FamilyScopeReader(
      auth: () => HavenBackend.auth,
      rows: () => HavenBackend.rows,
    ),
    rows: () => HavenBackend.rows,
    writer: () => HavenBackend.writer,
  );

  static String _now() => DateTime.now().toUtc().toIso8601String();

  @override
  Future<Result<List<Device>>> pairedDevices() async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) {
      return FamilyScopeReader.isMissingFamily(scope.failureOrNull!)
          ? const Ok<List<Device>>([])
          : Err<List<Device>>(scope.failureOrNull!);
    }
    final Result<List<Map<String, Object?>>> rows = await _rows().rows(
      TableName.devices,
      eq: {'family_id': mine.familyId},
      orderDesc: 'created_at',
    );
    final HavenFailure? failure = rows.failureOrNull;
    if (failure != null) return Err<List<Device>>(failure);
    return Ok<List<Device>>(
      rows.valueOrNull!.map(Device.fromRow).toList(growable: false),
    );
  }

  @override
  Future<Result<Device>> device(String deviceId) async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<Device>(scope.failureOrNull!);
    final Result<Map<String, Object?>?> row = await _rows().first(
      TableName.devices,
      eq: {'id': deviceId, 'family_id': mine.familyId},
    );
    final HavenFailure? failure = row.failureOrNull;
    if (failure != null) return Err<Device>(failure);
    final Map<String, Object?>? found = row.valueOrNull;
    if (found == null) {
      return const Err<Device>(
        ValidationFailure(
          'That device is not saved on this phone.',
          field: 'device',
        ),
      );
    }
    return Ok<Device>(Device.fromRow(found));
  }

  @override
  Future<Result<Device>> createDevice({
    required String displayName,
    required String childUserId,
    String platform = 'android',
    int? batteryLevel,
  }) async {
    final String trimmed = displayName.trim();
    if (trimmed.isEmpty || trimmed.length > 80) {
      return const Err<Device>(
        ValidationFailure(
          'Use between 1 and 80 characters.',
          field: 'display_name',
        ),
      );
    }
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<Device>(scope.failureOrNull!);

    final String deviceId = LocalIds.create();
    final String now = _now();
    final Map<String, Object?> row = <String, Object?>{
      'id': deviceId,
      'family_id': mine.familyId,
      'child_user_id': childUserId,
      'installation_id': 'sim-$deviceId',
      'display_name': trimmed,
      'platform': platform,
      'enforcement_mode': 'block',
      'policy_version': 1,
      'status': 'active',
      'battery_level': batteryLevel ?? 85,
      'is_charging': false,
      'last_seen_at': now,
      'created_at': now,
      'updated_at': now,
    };
    final Result<void> inserted = await _writer().insert(
      TableName.devices,
      row,
    );
    if (inserted.isErr) return Err<Device>(inserted.failureOrNull!);
    return Ok<Device>(Device.fromRow(row));
  }

  @override
  Future<Result<void>> rename({
    required String deviceId,
    required String name,
  }) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 80) {
      return const Err<void>(
        ValidationFailure(
          'Use between 1 and 80 characters.',
          field: 'display_name',
        ),
      );
    }
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<void>(scope.failureOrNull!);

    return _writer().update(
      TableName.devices,
      <String, Object?>{'display_name': trimmed, 'updated_at': _now()},
      eq: {'id': deviceId, 'family_id': mine.familyId},
    );
  }

  @override
  Future<Result<void>> assignChild({
    required String deviceId,
    required String childUserId,
  }) async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<void>(scope.failureOrNull!);

    return _writer().update(
      TableName.devices,
      <String, Object?>{'child_user_id': childUserId, 'updated_at': _now()},
      eq: {'id': deviceId, 'family_id': mine.familyId},
    );
  }

  @override
  Future<Result<void>> revoke(String deviceId, {bool execute = false}) async {
    if (!execute) return okVoid();
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<void>(scope.failureOrNull!);
    return _writer().update(
      TableName.devices,
      <String, Object?>{
        'status': 'revoked',
        'credential_revoked_at': _now(),
        'updated_at': _now(),
      },
      eq: {'id': deviceId, 'family_id': mine.familyId},
    );
  }

  @override
  Future<Result<void>> unlink(String deviceId) =>
      revoke(deviceId, execute: true);

  @override
  Future<Result<void>> requestRecovery(String deviceId) async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) return Err<void>(scope.failureOrNull!);
    return _writer().insert(TableName.auditLogs, <String, Object?>{
      'id': LocalIds.create(),
      'family_id': mine.familyId,
      'device_id': deviceId,
      'action': 'local_recovery_requested',
      'detail': 'recorded on this phone only — no device was contacted',
      'created_at': _now(),
    });
  }
}
