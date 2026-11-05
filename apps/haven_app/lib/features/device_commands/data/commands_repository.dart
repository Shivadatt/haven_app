import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../core/errors/captured_gaps.dart';
import '../../child_devices/data/devices_repository.dart';
import '../../family/data/family_scope.dart';
import 'commands_models.dart';

/// The instructions this family is allowed to read.
///
/// `device_commands` has a SELECT policy and grant for a parent, or for the child
/// who owns the device (`docs/stage1/04-rls-matrix.md:43`, `:98`), so the rows are
/// reachable — and it is one of the four tables Realtime is live on, which is why
/// the policy itself has to be right. Every way of *making* an instruction is
/// closed: no INSERT, UPDATE or DELETE grant exists for any client role (`:99-101`),
/// the two RPCs that would move the queue hold no EXECUTE for this role, and the
/// `device-command` Edge Function is not deployed. So this repository reads and
/// states that refusal; it has no send method, because no button on any screen
/// could succeed at one.
abstract interface class CommandsRepository {
  /// Null means this account has no family yet, which the screen routes to setup.
  ///
  /// [deviceId] narrows the read; the caller's own family id always goes with it,
  /// so a supplied id cannot reach another family's instructions.
  Future<Result<CommandBoard?>> load({String? deviceId});
}

final class HavenCommandsRepository implements CommandsRepository {
  HavenCommandsRepository({
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

  static const String writeMissing =
      '`device_commands` has no INSERT, UPDATE or DELETE grant for any client '
      'role (04-rls-matrix.md:99-101); the two RPCs that would move the queue, '
      '`poll_device_commands` and `expire_stale_commands`, sit behind the same '
      'wall as every other one — ${CapturedGaps.rpcLaneMissing} — and the '
      '`device-command` Edge Function is not deployed';

  /// The one refusal behind sending, cancelling and answering an instruction.
  static BlockedFailure get writeGap => BlockedFailure(
    'Haven cannot send, cancel or answer an instruction in this build yet.',
    missing: writeMissing,
    detail: 'BLOCKED — SPECIFICATION REQUIRED: $writeMissing',
  );

  @override
  Future<Result<CommandBoard?>> load({String? deviceId}) async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) {
      final HavenFailure why = scope.failureOrNull!;
      return FamilyScopeReader.isMissingFamily(why)
          ? const Ok<CommandBoard?>(null)
          : Err<CommandBoard?>(why);
    }

    final Result<List<Map<String, Object?>>> rows = await _rows().rows(
      TableName.deviceCommands,
      eq: <String, Object?>{
        'family_id': mine.familyId,
        // Omitted rather than sent as null: an empty id would filter the read
        // down to a device that does not exist.
        'device_id': ?deviceId,
      },
      orderDesc: 'created_at',
      limit: CommandBoard.window,
    );
    final HavenFailure? readFailure = rows.failureOrNull;
    if (readFailure != null) return Err<CommandBoard?>(readFailure);

    // The device lane is attempted, not assumed. When it answers, the rows get
    // their addressees back; when it refuses, the refusal travels with the board.
    final Result<List<Device>> owners = await _devices().pairedDevices();
    final List<Device>? named = owners.valueOrNull;
    final BlockedFailure? gap = owners.failureOrNull is BlockedFailure
        ? owners.failureOrNull as BlockedFailure
        : null;

    final List<CommandLine> lines = rows.valueOrNull!
        .map((Map<String, Object?> row) {
          final DeviceCommand command = DeviceCommand.fromRow(row);
          return CommandLine(
            command,
            deviceName: named == null ? null : _nameOf(named, command.deviceId),
          );
        })
        .toList(growable: false);

    return Ok<CommandBoard?>(
      CommandBoard(
        familyId: mine.familyId,
        deviceId: deviceId,
        lines: lines,
        writeGap: writeGap,
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
