import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/family/data/family_scope.dart';
import 'package:haven_app/features/safe_zones/data/zones_models.dart';
import 'package:haven_app/features/safe_zones/data/zones_repository.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../support/data_fakes.dart';
import '../support/fakes.dart';
import 'fakes.dart';

/// The safe-place repository with its three seams exposed.
///
/// The writer is a seam of its own because this is the only feature in the app
/// that writes: what a test needs to see is the payload and the matchers, not
/// just that a call happened.
final class Harness {
  Harness({
    Map<String, List<Map<String, Object?>>>? tables,
    FakeRowReader? withRows,
    FakeRowWriter? withWriter,
    FakeUserAuth? withAuth,
  }) : rows = withRows ?? FakeRowReader(tables ?? zonesTables()),
       writer = withWriter ?? FakeRowWriter(),
       auth = withAuth ?? FakeUserAuth(session) {
    scope = FamilyScopeReader(auth: () => auth, rows: () => rows);
    subject = HavenSafeZonesRepository(
      scope: () => scope,
      rows: () => rows,
      writer: () => writer,
    );
  }

  static const AuthSession session = AuthSession(
    userId: 'u1',
    email: 'parent@example.invalid',
    accessToken: 't',
  );

  final FakeRowReader rows;
  final FakeRowWriter writer;
  final FakeUserAuth auth;
  late final FamilyScopeReader scope;
  late final HavenSafeZonesRepository subject;

  /// The board from a read that is expected to succeed.
  Future<ZoneBoard> okBoard() async {
    final Result<ZoneBoard?> read = await subject.load();
    final ZoneBoard? board = read.valueOrNull;
    if (board == null) {
      throw StateError(
        'the read was expected to succeed: ${read.failureOrNull}',
      );
    }
    return board;
  }

  Future<SafeZone> okZone(String zoneId) async {
    final Result<SafeZone> read = await subject.zone(zoneId);
    final SafeZone? found = read.valueOrNull;
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
