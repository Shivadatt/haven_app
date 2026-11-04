import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/device_commands/data/commands_models.dart';
import 'package:haven_app/features/device_commands/data/commands_repository.dart';
import 'package:haven_app/features/family/data/family_scope.dart';
import 'package:haven_core/haven_core.dart';

import '../child_devices/fakes.dart';
import '../support/data_fakes.dart';
import '../support/fakes.dart';
import 'fakes.dart';

/// The instruction repository with its three seams exposed, so a test can say
/// which one answered: the scope, the rows, or the device lane that would name
/// the addressee of each row.
final class Harness {
  Harness({
    Map<String, List<Map<String, Object?>>>? tables,
    FakeRowReader? withRows,
    FakeDevicesRepository? withDevices,
    FakeUserAuth? withAuth,
  }) : rows = withRows ?? FakeRowReader(tables ?? commandTables()),
       devices = withDevices ?? FakeDevicesRepository(),
       auth = withAuth ?? FakeUserAuth(session) {
    scope = FamilyScopeReader(auth: () => auth, rows: () => rows);
    subject = HavenCommandsRepository(
      scope: () => scope,
      rows: () => rows,
      devices: () => devices,
    );
  }

  static const AuthSession session = AuthSession(
    userId: 'u1',
    email: 'parent@example.invalid',
    accessToken: 't',
  );

  final FakeRowReader rows;
  final FakeDevicesRepository devices;
  final FakeUserAuth auth;
  late final FamilyScopeReader scope;
  late final HavenCommandsRepository subject;

  /// The board from a read that is expected to succeed.
  Future<CommandBoard> okBoard({String? deviceId}) async {
    final Result<CommandBoard?> read = await subject.load(deviceId: deviceId);
    final CommandBoard? board = read.valueOrNull;
    if (board == null) {
      throw StateError(
        'the read was expected to succeed: ${read.failureOrNull}',
      );
    }
    return board;
  }

  /// A signed-in parent with no membership row, which is the first-run state
  /// every screen has to route on.
  factory Harness.withoutFamily() =>
      Harness(withRows: FakeRowReader({TableName.familyMembers: const []}));
}
