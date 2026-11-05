import 'package:haven_models/haven_models.dart';
import 'package:haven_app/features/family/data/family_models.dart';

/// Fixtures both family suites need: a person is a membership row plus the
/// profile row that may or may not exist.
FamilyPerson parent(String userId, String name) => FamilyPerson(
  member: FamilyMember(
    id: 'm-$userId',
    familyId: 'f1',
    userId: userId,
    role: 'parent',
    status: 'active',
    createdAt: DateTime.utc(2026, 1, 5),
  ),
  profile: Profile(id: userId, role: 'parent', displayName: name),
);

FamilyPerson child(
  String userId,
  String name, {
  String? ageBracket,
  String? avatar,
}) => FamilyPerson(
  member: FamilyMember(
    id: 'm-$userId',
    familyId: 'f1',
    userId: userId,
    role: 'child',
    status: 'active',
    createdAt: DateTime.utc(2026, 1, 5),
  ),
  profile: Profile(
    id: userId,
    role: 'child',
    displayName: name,
    ageBracket: ageBracket,
    avatar: avatar,
  ),
);

/// A member whose profile row was never provisioned.
FamilyPerson childWithoutProfile(String userId) => FamilyPerson(
  member: FamilyMember(
    id: 'm-$userId',
    familyId: 'f1',
    userId: userId,
    role: 'child',
    status: 'active',
    createdAt: DateTime.utc(2026, 1, 5),
  ),
);

FamilyBundle bundle({
  String name = 'Rivera',
  List<FamilyPerson> parents = const [],
  List<FamilyPerson> children = const [],
}) => FamilyBundle(
  family: Family(
    id: 'f1',
    name: name,
    ownerId: 'u1',
    settings: const <String, Object?>{},
    createdAt: DateTime.utc(2026, 1, 1),
  ),
  parents: parents.isEmpty ? const [FamilyPerson(member: _me)] : parents,
  children: children,
);

const FamilyMember _me = FamilyMember(
  id: 'm1',
  familyId: 'f1',
  userId: 'u1',
  role: 'parent',
  status: 'active',
);
