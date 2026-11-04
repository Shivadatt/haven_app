import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/device_pairing/data/pairing_repository.dart';
import 'package:haven_app/features/family/data/family_models.dart';
import 'package:haven_app/features/family/data/family_scope.dart';

import '../family/fakes.dart';
import '../support/data_fakes.dart';
import '../support/fakes.dart';

/// The rows are the nine columns `public.pairing_requests` actually has
/// (`docs/stage2/migrations/A3-staging-load-v1.sql:289-299`), so a fixture that
/// drifts from them drifts the test away from the table it is reading.
const String familyId = 'f1';

const AuthSession session = AuthSession(
  userId: 'u1',
  email: 'parent@example.invalid',
  accessToken: 't',
);

Map<String, Object?> requestRow(
  String id,
  String childUserId, {
  String status = 'pending_child',
  String createdAt = '2026-11-01T09:00:00.000Z',
  String expiresAt = '2026-11-01T09:20:00.000Z',
  String? respondedAt,
}) => {
  'id': id,
  'token_id': 't-$id',
  'family_id': familyId,
  'parent_user_id': 'u1',
  'child_user_id': childUserId,
  'status': status,
  'created_at': createdAt,
  'expires_at': expiresAt,
  'responded_at': respondedAt,
};

/// Another family's request — the read is filtered by `family_id`, and a test
/// needs a row the filter has to reject.
Map<String, Object?> otherFamilyRow(String id) => {
  ...requestRow(id, 'c1'),
  'family_id': 'f2',
};

Map<String, List<Map<String, Object?>>> pairingTables({
  List<Map<String, Object?>> requests = const [],
}) => {
  TableName.families: [
    {
      'id': familyId,
      'name': 'Rivera',
      'owner_id': 'u1',
      'settings': <String, Object?>{},
    },
  ],
  TableName.familyMembers: [
    {
      'id': 'm1',
      'family_id': familyId,
      'user_id': 'u1',
      'role': 'parent',
      'status': 'active',
      'created_at': '2026-01-05T10:00:00.000Z',
    },
  ],
  TableName.profiles: [
    {'id': 'u1', 'role': 'parent', 'display_name': 'Rae'},
  ],
  TableName.pairingRequests: requests,
};

/// The repository under test with its three seams visible.
final class Harness {
  Harness({
    Map<String, List<Map<String, Object?>>>? tables,
    FakeRowReader? withRows,
    FakeFamilyRepository? withFamily,
  }) : rows = withRows ?? FakeRowReader(tables ?? pairingTables()),
       names = withFamily ?? FakeFamilyRepository(bundle: namedFamily()) {
    scope = FamilyScopeReader(
      auth: () => FakeUserAuth(session),
      rows: () => rows,
    );
    subject = HavenPairingRepository(
      scope: () => scope,
      rows: () => rows,
      family: () => names,
    );
  }

  /// Ivy and Kai, so a resolved name proves the family read was used rather
  /// than a name invented from the request row.
  static FamilyBundle namedFamily() =>
      bundle(children: [child('c1', 'Ivy'), child('c2', 'Kai')]);

  final FakeRowReader rows;
  final FakeFamilyRepository names;
  late final FamilyScopeReader scope;
  late final HavenPairingRepository subject;
}
