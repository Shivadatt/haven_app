import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';
import 'package:haven_app/features/family/data/family_models.dart';
import 'package:haven_app/features/family/data/family_repository.dart';

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

FamilyPerson child(String userId, String name) => FamilyPerson(
  member: FamilyMember(
    id: 'm-$userId',
    familyId: 'f1',
    userId: userId,
    role: 'child',
    status: 'active',
    createdAt: DateTime.utc(2026, 1, 5),
  ),
  profile: Profile(id: userId, role: 'child', displayName: name),
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

/// The family screen's answers, driven by the test.
class FakeFamilyRepository implements FamilyRepository {
  FakeFamilyRepository({this.bundle});

  /// Null payload = this account has no family yet, which is a state rather
  /// than a failure.
  FamilyBundle? bundle;

  HavenFailure? loadFailWith;
  HavenFailure? renameFailWith;
  HavenFailure? unlinkFailWith;

  /// What the abilities with no approved contract answer. A real repository
  /// returns a [BlockedFailure]; a test can put anything here.
  HavenFailure? blockedWith;

  final List<String> calls = [];
  String? lastName;
  String? lastChildUserId;

  @override
  Future<Result<FamilyBundle?>> load() async {
    calls.add('load');
    final HavenFailure? failure = loadFailWith;
    if (failure != null) return Err<FamilyBundle?>(failure);
    return Ok<FamilyBundle?>(bundle);
  }

  @override
  Future<Result<void>> rename({required String name}) async {
    calls.add('rename');
    lastName = name;
    final HavenFailure? failure = renameFailWith;
    return failure == null ? okVoid() : Err<void>(failure);
  }

  /// The production repository refuses this outright — the app role has no
  /// EXECUTE on `unlink_child` — so the fake refuses too, and only answers
  /// `unlinkFailWith` when a test wants a different refusal.
  @override
  Future<Result<void>> unlinkChild(String childUserId) async {
    calls.add('unlinkChild');
    lastChildUserId = childUserId;
    final HavenFailure? failure = unlinkFailWith;
    if (failure != null) return Err<void>(failure);
    return _blocked('removing a child');
  }

  @override
  Future<Result<void>> inviteParent() async {
    calls.add('inviteParent');
    return _blocked('adding a parent');
  }

  @override
  Future<Result<void>> removeParent() async {
    calls.add('removeParent');
    return _blocked('removing a parent');
  }

  Future<Result<void>> _blocked(String what) async => blockedWith == null
      ? blocked<void>('fake: no contract for $what')
      : Err<void>(blockedWith!);
}
