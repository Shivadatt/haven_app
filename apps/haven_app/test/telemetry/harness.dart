import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/family/data/family_scope.dart';
import 'package:haven_app/features/telemetry/data/telemetry_models.dart';
import 'package:haven_app/features/telemetry/data/telemetry_repository.dart';
import 'package:haven_core/haven_core.dart';

import '../child_devices/fakes.dart';
import '../support/data_fakes.dart';
import '../support/fakes.dart';
import 'fakes.dart';

/// The trail repository with its three seams exposed, so a test can say which one
/// answered: the scope, the rows, or the device lane.
final class Harness {
  Harness({
    Map<String, List<Map<String, Object?>>>? tables,
    FakeRowReader? withRows,
    FakeDevicesRepository? withDevices,
    FakeUserAuth? withAuth,
  }) : rows = withRows ?? FakeRowReader(tables ?? trailTables()),
       devices = withDevices ?? FakeDevicesRepository(),
       auth = withAuth ?? FakeUserAuth(session) {
    scope = FamilyScopeReader(auth: () => auth, rows: () => rows);
    subject = HavenTelemetryRepository(
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
  late final HavenTelemetryRepository subject;

  /// The board from a read that is expected to succeed.
  Future<TelemetryBoard> okBoard({String? deviceId}) async {
    final Result<TelemetryBoard?> read = await subject.load(deviceId: deviceId);
    final TelemetryBoard? board = read.valueOrNull;
    if (board == null) {
      throw StateError(
        'the read was expected to succeed: ${read.failureOrNull}',
      );
    }
    return board;
  }

  /// A signed-in parent with no membership row, which is the first-run state.
  factory Harness.withoutFamily() =>
      Harness(withRows: FakeRowReader({TableName.familyMembers: const []}));
}
