import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../child_devices/data/devices_repository.dart';
import '../../family/data/family_scope.dart';
import 'alerts_models.dart';

/// The reports the backend has written for this family.
///
/// `safety_alerts` carries SELECT for a parent, or for the child who owns the
/// device (`docs/stage1/04-rls-matrix.md:56`, `:150`,
/// `A3-staging-load-v1.sql:913`), so the list is reachable. Both lanes beside it
/// are closed: acknowledging a row is a column write held by `service_role` alone
/// (`sql:1102-1103`), and a push token has nowhere to be stored. So this reads and
/// states the refusals instead of offering a "mark as read" that could only be
/// refused, and it leaves the device-side token work to `PushTransport` and the
/// permission question to the settings screen that already owns them.
abstract interface class AlertsRepository {
  /// Null means this account has no family yet, which the screen routes to setup.
  Future<Result<AlertBoard?>> load();

  Future<Result<void>> markAsRead(String alertId, {String? userId});

  Future<Result<void>> markAsUnread(String alertId);

  Future<Result<void>> deleteAlert(String alertId);
}

final class HavenAlertsRepository implements AlertsRepository {
  HavenAlertsRepository({
    required FamilyScopeReader Function() scope,
    required RowReader Function() rows,
    required DevicesRepository Function() devices,
  }) : _scope = scope,
       _rows = rows,
       _devices = devices;

  /// Providers, not values: `HavenBackend.install()` is asynchronous.
  final FamilyScopeReader Function() _scope;
  final RowReader Function() _rows;
  final DevicesRepository Function() _devices;

  static const String ackMissing =
      '`safety_alerts` gives `authenticated` SELECT and nothing else — INSERT, '
      'UPDATE and DELETE belong to `service_role` (04-rls-matrix.md:151-153, '
      'A3-staging-load-v1.sql:913-914), and the two columns that would record an '
      'answer, `acknowledged_at` and `acknowledged_by`, are granted for UPDATE to '
      '`service_role` alone (`:1102-1103`); no RPC and no deployed Edge Function '
      'would take the mark from a parent';

  static const String deliveryMissing =
      'a push token has nowhere to be put: `devices` holds no token column and no '
      '`push_tokens` table exists in the capture '
      '(docs/stage1/evidence/schema-columns.md:294), the columns that would hold '
      'one are drafted only in `A3c-notification-backend.sql`, which no approval '
      'instrument covers and staging has not loaded, and `register-token` is not '
      'among the captured Edge Functions (00-app-contract.md:17)';

  /// Built once so the board and the card hand round the very same instance.
  static final BlockedFailure ackGap = BlockedFailure(
    'Haven cannot mark a report as read or answered in this build yet.',
    missing: ackMissing,
    detail: 'BLOCKED — SPECIFICATION REQUIRED: $ackMissing',
  );

  static final BlockedFailure deliveryGap = BlockedFailure(
    'Haven cannot register this device to be pushed to in this build yet.',
    missing: deliveryMissing,
    detail: 'BLOCKED — SPECIFICATION REQUIRED: $deliveryMissing',
  );

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
    final BlockedFailure? gap = owners.failureOrNull is BlockedFailure
        ? owners.failureOrNull as BlockedFailure
        : null;

    final List<AlertLine> lines = rows.valueOrNull!
        .map((Map<String, Object?> row) {
          final SafetyAlert alert = SafetyAlert.fromRow(row);
          return AlertLine(
            alert,
            deviceName: named == null ? null : _nameOf(named, alert.deviceId),
          );
        })
        .toList(growable: false);

    return Ok<AlertBoard?>(
      AlertBoard(
        familyId: mine.familyId,
        lines: lines,
        ackGap: ackGap,
        deliveryGap: deliveryGap,
        deviceGap: gap,
      ),
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

  @override
  Future<Result<void>> markAsRead(String alertId, {String? userId}) async =>
      Err<void>(ackGap);

  @override
  Future<Result<void>> markAsUnread(String alertId) async =>
      Err<void>(ackGap);

  @override
  Future<Result<void>> deleteAlert(String alertId) async =>
      Err<void>(ackGap);
}
