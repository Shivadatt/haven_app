import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/family/data/family_repository.dart';
import 'package:haven_app/features/family/data/family_scope.dart';

import '../support/data_fakes.dart';
import '../support/fakes.dart';

/// Rows are what the captured tables actually hold, so a fixture that drifts
/// from them drifts the test away from the contract it is checking.
const String familyId = 'f1';

const AuthSession session = AuthSession(
  userId: 'u1',
  email: 'parent@example.invalid',
  accessToken: 't',
);

Map<String, Object?> familyRow({String name = 'Rivera'}) => {
  'id': familyId,
  'name': name,
  'owner_id': 'u1',
  'settings': <String, Object?>{},
};

Map<String, Object?> memberRow(
  String userId,
  String role, {
  String status = 'active',
}) => {
  'id': 'm-$userId',
  'family_id': familyId,
  'user_id': userId,
  'role': role,
  'status': status,
  'created_at': '2026-01-05T10:00:00.000Z',
};

Map<String, Object?> profileRow(String userId, String displayName) => {
  'id': userId,
  'role': 'parent',
  'display_name': displayName,
};

/// The signed-in parent, plus whatever else the test adds.
Map<String, List<Map<String, Object?>>> fullTables({
  List<Map<String, Object?>> members = const [],
  List<Map<String, Object?>> profiles = const [],
}) => {
  TableName.families: [familyRow()],
  TableName.familyMembers: [memberRow('u1', 'parent'), ...members],
  TableName.profiles: [profileRow('u1', 'Rae'), ...profiles],
};

/// An account that is signed in but has no family row of its own.
Map<String, List<Map<String, Object?>>> noFamilyTables() => {
  TableName.families: [familyRow()],
  TableName.familyMembers: const <Map<String, Object?>>[],
  TableName.profiles: const <Map<String, Object?>>[],
};

/// The repository under test with its three seams visible.
final class Harness {
  Harness({
    Map<String, List<Map<String, Object?>>>? tables,
    FakeUserAuth? withAuth,
    FakeRowReader? withRows,
  }) : auth = withAuth ?? FakeUserAuth(session),
       rows = withRows ?? FakeRowReader(tables ?? fullTables()),
       writer = FakeRowWriter() {
    scope = FamilyScopeReader(auth: () => auth, rows: () => rows);
    subject = HavenFamilyRepository(
      scope: () => scope,
      rows: () => rows,
      writer: () => writer,
    );
  }

  final FakeUserAuth auth;
  final FakeRowReader rows;
  final FakeRowWriter writer;
  late final FamilyScopeReader scope;
  late final HavenFamilyRepository subject;
}
