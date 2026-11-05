import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../child_devices/data/devices_repository.dart';
import '../../family/data/family_scope.dart';
import 'activity_models.dart';

/// App use the family is allowed to see.
///
/// One read, one refusal: `usage_daily` has a SELECT policy for a parent of the
/// family (`docs/stage1/04-rls-matrix.md:154`), so the rows are reachable, while
/// the `devices` table that would name them is not (F6, :46). A day's total for a
/// package is therefore shown with the device left unnamed, and the reason stated.
abstract interface class ActivityRepository {
  /// Null means this account has no family yet, which the screen routes to setup.
  ///
  /// [deviceId] narrows the read to one device — the route argument
  /// `docs/implementation/00-app-contract.md:162` fixes for this screen. It is
  /// never the only filter: the family id from the caller's own membership row
  /// always goes with it, so a made-up device id returns nothing rather than
  /// another family's rows.
  Future<Result<UsageBoard?>> load({String? deviceId});

  Future<Result<void>> logActivityEvent({
    required String familyId,
    required String deviceId,
    required String category,
    required String title,
    required String subtitle,
    Map<String, Object?>? payload,
  });
}

final class HavenActivityRepository implements ActivityRepository {
  HavenActivityRepository({
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

    final Result<List<Map<String, Object?>>> rows = await _rows().rows(
      TableName.usageDaily,
      eq: <String, Object?>{
        'family_id': mine.familyId,
        // Omitted rather than sent as null: an empty id would filter the read
        // down to a device that does not exist.
        'device_id': ?deviceId,
      },
      orderDesc: 'day',
      limit: UsageBoard.window,
    );
    final HavenFailure? readFailure = rows.failureOrNull;
    if (readFailure != null) return Err<UsageBoard?>(readFailure);

    // The device lane is attempted, not assumed. When it answers, the rows get
    // their owners back; when it refuses, the refusal travels with the board.
    final Result<List<Device>> owners = await _devices().pairedDevices();
    final List<Device>? named = owners.valueOrNull;
    final BlockedFailure? gap = owners.failureOrNull is BlockedFailure
        ? owners.failureOrNull as BlockedFailure
        : null;

    final List<UsageLine> lines = rows.valueOrNull!
        .map((Map<String, Object?> row) {
          final UsageDaily usage = UsageDaily.fromRow(row);
          return UsageLine(
            usage,
            deviceName: named == null ? null : _nameOf(named, usage.deviceId),
          );
        })
        .toList(growable: false);

    return Ok<UsageBoard?>(
      UsageBoard(
        familyId: mine.familyId,
        deviceId: deviceId,
        lines: lines,
        deviceGap: gap,
      ),
    );
  }

  static String? _nameOf(List<Device> devices, String id) {
    for (final Device device in devices) {
      if (device.id == id) {
        return device.displayName.isEmpty ? null : device.displayName;
      }
    }
    return null;
  }

  @override
  Future<Result<void>> logActivityEvent({
    required String familyId,
    required String deviceId,
    required String category,
    required String title,
    required String subtitle,
    Map<String, Object?>? payload,
  }) async => Err<void>(
    BlockedFailure(
      'Activity logging is not available in cloud mode without custom Edge Functions.',
      missing: 'no custom edge function exists to ingest client-side activity events',
    ),
  );
}
