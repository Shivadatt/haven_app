import 'package:haven_core/haven_core.dart';
import 'package:haven_app/features/family/data/family_models.dart';
import 'package:haven_app/features/family/data/family_repository.dart';

import 'family_fixtures.dart';

export 'family_fixtures.dart';

/// The family screen's answers, driven by the test.
class FakeFamilyRepository implements FamilyRepository {
  FakeFamilyRepository({this.bundle});

  FamilyBundle? bundle;

  HavenFailure? loadFailWith;
  HavenFailure? renameFailWith;
  HavenFailure? unlinkFailWith;
  HavenFailure? addChildFailWith;
  HavenFailure? updateChildFailWith;
  HavenFailure? createFamilyFailWith;

  HavenFailure? blockedWith;

  final List<String> calls = [];
  String? lastName;
  String? lastChildUserId;
  String? lastChildName;
  String? lastAgeBracket;
  String? lastAvatar;

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

  @override
  Future<Result<void>> unlinkChild(
    String childUserId, {
    bool execute = false,
  }) async {
    calls.add('unlinkChild');
    lastChildUserId = childUserId;
    final HavenFailure? failure = unlinkFailWith;
    if (failure != null) return Err<void>(failure);
    if (!execute) return _blocked('removing a child');
    if (bundle != null) {
      bundle = FamilyBundle(
        family: bundle!.family,
        parents: bundle!.parents,
        children: bundle!.children.where((c) => c.userId != childUserId).toList(),
      );
    }
    return okVoid();
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

  @override
  Future<Result<void>> createFamily({required String name}) async {
    calls.add('createFamily');
    lastName = name;
    final HavenFailure? failure = createFamilyFailWith;
    return failure == null ? okVoid() : Err<void>(failure);
  }

  @override
  Future<Result<FamilyPerson>> addChild({
    required String name,
    String? ageBracket,
    String? avatar,
  }) async {
    calls.add('addChild');
    lastChildName = name;
    lastAgeBracket = ageBracket;
    lastAvatar = avatar;
    final HavenFailure? failure = addChildFailWith;
    if (failure != null) return Err<FamilyPerson>(failure);
    final String id = 'c-${calls.length}';
    final FamilyPerson newPerson = child(
      id,
      name,
      ageBracket: ageBracket,
      avatar: avatar,
    );
    if (bundle != null) {
      bundle = FamilyBundle(
        family: bundle!.family,
        parents: bundle!.parents,
        children: [...bundle!.children, newPerson],
      );
    }
    return Ok<FamilyPerson>(newPerson);
  }

  @override
  Future<Result<void>> updateChild({
    required String childUserId,
    required String name,
    String? ageBracket,
    String? avatar,
  }) async {
    calls.add('updateChild');
    lastChildUserId = childUserId;
    lastChildName = name;
    lastAgeBracket = ageBracket;
    lastAvatar = avatar;
    final HavenFailure? failure = updateChildFailWith;
    if (failure != null) return Err<void>(failure);
    if (bundle != null) {
      bundle = FamilyBundle(
        family: bundle!.family,
        parents: bundle!.parents,
        children: bundle!.children.map((c) {
          if (c.userId != childUserId) return c;
          return child(childUserId, name, ageBracket: ageBracket, avatar: avatar);
        }).toList(),
      );
    }
    return okVoid();
  }

  Future<Result<void>> _blocked(String what) async => blockedWith == null
      ? blocked<void>('fake: no contract for $what')
      : Err<void>(blockedWith!);
}
