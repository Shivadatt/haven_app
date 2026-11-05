import 'package:haven_models/haven_models.dart';

/// One person in the family: the membership row, plus their profile if it exists.
final class FamilyPerson {
  const FamilyPerson({required this.member, this.profile});

  final FamilyMember member;

  /// Null when the profile row was never provisioned
  /// (`docs/stage2/S2-EXEC-08-identity-decision-A13-final.md` §2(4)).
  final Profile? profile;

  String get userId => member.userId;
  bool get hasProfile => profile != null;
  String? get ageBracket => profile?.ageBracket;
  String? get avatar => profile?.avatar;

  /// A member with no name still has to be listed — hiding a child from their
  /// own family would be worse than the placeholder.
  String get name {
    final String written = (profile?.displayName ?? '').trim();
    if (written.isNotEmpty) return written;
    final FamilyRole? role = member.familyRole;
    return role == null ? 'A family member' : 'A ${role.label.toLowerCase()}';
  }
}

/// The family and everyone in it, as one read.
final class FamilyBundle {
  const FamilyBundle({
    required this.family,
    required this.parents,
    required this.children,
  });

  final Family family;
  final List<FamilyPerson> parents;
  final List<FamilyPerson> children;
}
