import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../core/errors/captured_gaps.dart';
import '../../child_devices/data/devices_repository.dart';
import '../../family/data/family_scope.dart';
import 'telemetry_models.dart';

/// The family's own trail — what the backend recorded being changed.
///
/// `audit_logs` has a SELECT policy and grant for a parent of the family
/// (`docs/stage1/04-rls-matrix.md:40`, `:86`) and no INSERT, UPDATE or DELETE path
/// for any client (`:87-89`), so this is a read of a log no app screen can write or
/// clear. The other half of the telemetry feature — whether a device is online — is
/// a `devices` status column read plus the `detect_offline_devices` sweep, and both
/// are closed; that refusal travels on the board instead of becoming a guess.
abstract interface class TelemetryRepository {
  /// Null means this account has no family yet.
  ///
  /// [deviceId] narrows the read; the caller's own family id always goes with it,
  /// so a supplied id cannot reach another family's entries.
  Future<Result<TelemetryBoard?>> load({String? deviceId});
}

final class HavenTelemetryRepository implements TelemetryRepository {
  HavenTelemetryRepository({
    required this._scope,
    required this._rows,
    required this._devices,
  });

  /// Providers, not values: `HavenBackend.install()` is asynchronous.
  final FamilyScopeReader Function() _scope;
  final RowReader Function() _rows;
  final DevicesRepository Function() _devices;

  static const String offlineMissing =
      'the last-seen columns live on `devices`, which sits behind F6 — '
      '${CapturedGaps.deviceLaneMissing}; and `detect_offline_devices` takes no '
      'actor argument, is `SECURITY DEFINER`, and is one of the RPCs behind the '
      'same wall as every other one — ${CapturedGaps.rpcLaneMissing}. The '
      '`device-telemetry` Edge Function that would call it is not deployed';

  static BlockedFailure get offlineGap => BlockedFailure(
    'Haven cannot say whether a device is online in this build yet.',
    missing: offlineMissing,
    detail: 'BLOCKED — SPECIFICATION REQUIRED: $offlineMissing',
  );

  @override
  Future<Result<TelemetryBoard?>> load({String? deviceId}) async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) {
      final HavenFailure why = scope.failureOrNull!;
      return FamilyScopeReader.isMissingFamily(why)
          ? const Ok<TelemetryBoard?>(null)
          : Err<TelemetryBoard?>(why);
    }

    final Result<List<Map<String, Object?>>> rows = await _rows().rows(
      TableName.auditLogs,
      eq: <String, Object?>{
        'family_id': mine.familyId,
        // Omitted rather than sent as null: an empty id would filter the read
        // down to a device that does not exist.
        'device_id': ?deviceId,
      },
      orderDesc: 'created_at',
      limit: TelemetryBoard.window,
    );
    final HavenFailure? readFailure = rows.failureOrNull;
    if (readFailure != null) return Err<TelemetryBoard?>(readFailure);

    final Result<List<Device>> owners = await _devices().pairedDevices();
    final List<Device>? named = owners.valueOrNull;
    final BlockedFailure? gap = owners.failureOrNull is BlockedFailure
        ? owners.failureOrNull as BlockedFailure
        : null;

    final List<AuditLine> lines = rows.valueOrNull!
        .map((Map<String, Object?> row) {
          final AuditLog entry = AuditLog.fromRow(row);
          return AuditLine(
            entry,
            deviceName: named == null ? null : _nameOf(named, entry.deviceId),
          );
        })
        .toList(growable: false);

    return Ok<TelemetryBoard?>(
      TelemetryBoard(
        familyId: mine.familyId,
        deviceId: deviceId,
        lines: lines,
        offlineGap: offlineGap,
        deviceGap: gap,
      ),
    );
  }

  static String? _nameOf(List<Device> devices, String? id) {
    if (id == null || id.isEmpty) return null;
    for (final Device device in devices) {
      if (device.id == id) {
        return device.displayName.isEmpty ? null : device.displayName;
      }
    }
    return null;
  }
}
