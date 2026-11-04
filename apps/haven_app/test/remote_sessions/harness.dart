import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/family/data/family_scope.dart';
import 'package:haven_app/features/remote_sessions/data/session_detail_models.dart';
import 'package:haven_app/features/remote_sessions/data/sessions_models.dart';
import 'package:haven_app/features/remote_sessions/data/sessions_repository.dart';
import 'package:haven_core/haven_core.dart';

import '../child_devices/fakes.dart';
import '../support/data_fakes.dart';
import '../support/fakes.dart';
import 'fakes.dart';

/// The session repository with its seams exposed, so a test can say which one
/// answered: the scope, the rows, or the device lane that would name a session.
final class Harness {
  Harness({
    Map<String, List<Map<String, Object?>>>? tables,
    FakeRowReader? withRows,
    FakeDevicesRepository? withDevices,
    FakeUserAuth? withAuth,
  }) : rows = withRows ?? FakeRowReader(tables ?? sessionTables()),
       devices = withDevices ?? FakeDevicesRepository(),
       auth = withAuth ?? FakeUserAuth(session) {
    scope = FamilyScopeReader(auth: () => auth, rows: () => rows);
    subject = HavenSessionsRepository(
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
  late final HavenSessionsRepository subject;

  /// The board from a read that is expected to succeed.
  Future<SessionBoard> okBoard() async {
    final Result<SessionBoard?> read = await subject.load();
    final SessionBoard? board = read.valueOrNull;
    if (board == null) {
      throw StateError(
        'the read was expected to succeed: ${read.failureOrNull}',
      );
    }
    return board;
  }

  /// The detail from a read that is expected to succeed.
  Future<SessionDetail> okDetail(String sessionId) async {
    final Result<SessionDetail?> read = await subject.loadDetail(sessionId);
    final SessionDetail? found = read.valueOrNull;
    if (found == null) {
      throw StateError(
        'the read was expected to succeed: ${read.failureOrNull}',
      );
    }
    return found;
  }

  /// A signed-in parent with no membership row, which is the first-run state
  /// every screen has to route on.
  factory Harness.withoutFamily() =>
      Harness(withRows: FakeRowReader({TableName.familyMembers: const []}));
}
