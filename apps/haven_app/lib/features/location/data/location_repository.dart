import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../core/errors/captured_gaps.dart';
import '../../child_devices/data/devices_repository.dart';
import '../../family/data/family_scope.dart';
import 'location_models.dart';

/// The places this family is allowed to read.
///
/// `location_events` has a SELECT policy and a SELECT grant for a parent of the
/// family (`docs/stage1/04-rls-matrix.md:52`), so the rows are reachable. Two
/// things the screen would otherwise say are not: whose device a fix came from
/// (`devices` is unreachable — F6) and whether a fix was inside a named place
/// (`safe_zone_states` is deny-all). Both travel on the board as refusals, so the
/// page renders the boundary instead of guessing past it.
abstract interface class LocationRepository {
  /// Null means this account has no family yet, which the screen routes to setup.
  ///
  /// [deviceId] narrows the read; the caller's own family id always goes with it,
  /// so a supplied id cannot reach another family's fixes.
  Future<Result<FixBoard?>> load({String? deviceId});
}

final class HavenLocationRepository implements LocationRepository {
  HavenLocationRepository({
    required this._scope,
    required this._rows,
    required this._devices,
  });

  /// Providers, not values: `HavenBackend.install()` is asynchronous.
  final FamilyScopeReader Function() _scope;
  final RowReader Function() _rows;
  final DevicesRepository Function() _devices;

  @override
  Future<Result<FixBoard?>> load({String? deviceId}) async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) {
      final HavenFailure why = scope.failureOrNull!;
      return FamilyScopeReader.isMissingFamily(why)
          ? const Ok<FixBoard?>(null)
          : Err<FixBoard?>(why);
    }

    final Result<List<Map<String, Object?>>> rows = await _rows().rows(
      TableName.locationEvents,
      eq: <String, Object?>{'family_id': mine.familyId, 'device_id': ?deviceId},
      orderDesc: 'recorded_at',
      limit: FixBoard.window,
    );
    final HavenFailure? readFailure = rows.failureOrNull;
    if (readFailure != null) return Err<FixBoard?>(readFailure);

    final Result<List<Device>> owners = await _devices().pairedDevices();
    final List<Device>? named = owners.valueOrNull;
    final BlockedFailure? gap = owners.failureOrNull is BlockedFailure
        ? owners.failureOrNull as BlockedFailure
        : null;

    final List<FixLine> lines = rows.valueOrNull!
        .map((Map<String, Object?> row) {
          final LocationEvent fix = LocationEvent.fromRow(row);
          return FixLine(
            fix,
            deviceName: named == null ? null : _nameOf(named, fix.deviceId),
          );
        })
        .toList(growable: false);

    return Ok<FixBoard?>(
      FixBoard(
        familyId: mine.familyId,
        deviceId: deviceId,
        lines: lines,
        deviceGap: gap,
        presenceGap: CapturedGaps.presenceGap,
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
}
