import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../core/errors/captured_gaps.dart';
import '../../child_devices/data/devices_repository.dart';
import '../../family/data/family_scope.dart';
import 'policies_models.dart';

/// The policy versions this family is allowed to read.
///
/// `device_policies` has a SELECT policy and grant for a parent, or for the child
/// who owns the device (`docs/stage1/04-rls-matrix.md:45`, `:106`), so the rows are
/// reachable. Writing one is not: the table has no INSERT, UPDATE or DELETE grant
/// for any client role (`:107-109`), and `apply_policy_version` is one of the 14 RPCs
/// whose EXECUTE stops at `postgres` and `service_role`. This repository therefore
/// reads, and states both refusals, rather than offering a control that could only
/// ever be turned down.
abstract interface class PoliciesRepository {
  /// Null means this account has no family yet, which the screen routes to setup.
  ///
  /// [deviceId] narrows the read; the caller's own family id always goes with it,
  /// so a supplied id cannot reach another family's versions.
  Future<Result<PolicyBoard?>> load({String? deviceId});
}

final class HavenPoliciesRepository implements PoliciesRepository {
  HavenPoliciesRepository({
    required this._scope,
    required this._rows,
    required this._devices,
  });

  /// Providers, not values: `HavenBackend.install()` is asynchronous.
  final FamilyScopeReader Function() _scope;
  final RowReader Function() _rows;
  final DevicesRepository Function() _devices;

  static const String writeMissing =
      '`device_policies` has no INSERT, UPDATE or DELETE grant for any client '
      'role (04-rls-matrix.md:107-109); the RPC that would pass a version on, '
      '`apply_policy_version`, sits behind the same wall as every other one — '
      '${CapturedGaps.rpcLaneMissing} — and the `device-policy` Edge Function '
      'that holds a service role is not deployed';

  static const String ruleShapeMissing =
      '`device_policies.policy` is `jsonb NOT NULL` with one CHECK — '
      '`device_policies_policy_check`, which is only `jsonb_typeof(policy) = '
      '\'object\'` (A3-staging-load-v1.sql:454). No capture lists its keys, a '
      'unit for each value, or what a device does when two keys disagree, so a '
      'rule set cannot be rendered without inventing the language it is written '
      'in';

  static BlockedFailure get writeGap => BlockedFailure(
    'Haven cannot set or change a device\'s rules in this build yet.',
    missing: writeMissing,
    detail: 'BLOCKED — SPECIFICATION REQUIRED: $writeMissing',
  );

  static BlockedFailure get ruleShapeGap => BlockedFailure(
    'Haven cannot show what the rules in a version say in this build yet.',
    missing: ruleShapeMissing,
    detail: 'BLOCKED — SPECIFICATION REQUIRED: $ruleShapeMissing',
  );

  @override
  Future<Result<PolicyBoard?>> load({String? deviceId}) async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) {
      final HavenFailure why = scope.failureOrNull!;
      return FamilyScopeReader.isMissingFamily(why)
          ? const Ok<PolicyBoard?>(null)
          : Err<PolicyBoard?>(why);
    }

    final Result<List<Map<String, Object?>>> rows = await _rows().rows(
      TableName.devicePolicies,
      eq: <String, Object?>{
        'family_id': mine.familyId,
        // Omitted rather than sent as null: an empty id would filter the read
        // down to a device that does not exist.
        'device_id': ?deviceId,
      },
      orderDesc: 'created_at',
      limit: PolicyBoard.window,
    );
    final HavenFailure? readFailure = rows.failureOrNull;
    if (readFailure != null) return Err<PolicyBoard?>(readFailure);

    final Result<List<Device>> owners = await _devices().pairedDevices();
    final List<Device>? named = owners.valueOrNull;
    final BlockedFailure? gap = owners.failureOrNull is BlockedFailure
        ? owners.failureOrNull as BlockedFailure
        : null;

    final List<PolicyLine> lines = rows.valueOrNull!
        .map((Map<String, Object?> row) {
          final DevicePolicy policy = DevicePolicy.fromRow(row);
          return PolicyLine(
            policy,
            deviceName: named == null ? null : _nameOf(named, policy.deviceId),
          );
        })
        .toList(growable: false);

    return Ok<PolicyBoard?>(
      PolicyBoard(
        familyId: mine.familyId,
        deviceId: deviceId,
        lines: lines,
        writeGap: writeGap,
        ruleShapeGap: ruleShapeGap,
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
}
