import 'enums_identity.dart';
import 'json_utils.dart';

/// `public.profiles` — one row per authenticated person.
///
/// Provisioning a profile has no approved implementation yet
/// (`docs/stage2/S2-EXEC-08-identity-decision-A13-final.md` §2(4)), so callers
/// must handle "row does not exist" as a normal state, not an error.
final class Profile {
  const Profile({
    required this.id,
    required this.role,
    required this.displayName,
    this.ageBracket,
    this.avatar,
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromRow(Map<String, Object?> row) => Profile(
    id: asText(row['id']) ?? '',
    role: asText(row['role']),
    displayName: asText(row['display_name']) ?? '',
    ageBracket: asText(row['age_bracket']),
    avatar: asText(row['avatar']),
    createdAt: asDate(row['created_at']),
    updatedAt: asDate(row['updated_at']),
  );

  final String id;
  final String? role;
  final String displayName;
  final String? ageBracket;
  final String? avatar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Null when the token is not one of `unset|parent|child`, or absent.
  ProfileRole? get profileRole => ProfileRole.fromWire(role);

  Map<String, Object?> toRow() => {
    'id': id,
    if (role != null) 'role': role,
    'display_name': displayName,
    if (ageBracket != null) 'age_bracket': ageBracket,
    if (avatar != null) 'avatar': avatar,
  };

  @override
  String toString() => 'Profile($id, role: $role)';
}

/// `public.families`. `deleted_at` is non-null for a soft-deleted family.
final class Family {
  const Family({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.settings,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Family.fromRow(Map<String, Object?> row) => Family(
    id: asText(row['id']) ?? '',
    name: asText(row['name']) ?? '',
    ownerId: asText(row['owner_id']) ?? '',
    settings: asMap(row['settings']),
    createdAt: asDate(row['created_at']),
    updatedAt: asDate(row['updated_at']),
    deletedAt: asDate(row['deleted_at']),
  );

  final String id;
  final String name;
  final String ownerId;
  final Map<String, Object?> settings;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Map<String, Object?> toRow() => {
    'id': id,
    'name': name,
    'owner_id': ownerId,
    'settings': settings,
  };
}

/// `public.family_members` — `removed_at` and `status = 'removed'` are
/// constrained to agree with each other (`family_members_removed_consistency`).
final class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.role,
    required this.status,
    this.createdAt,
    this.removedAt,
  });

  factory FamilyMember.fromRow(Map<String, Object?> row) => FamilyMember(
    id: asText(row['id']) ?? '',
    familyId: asText(row['family_id']) ?? '',
    userId: asText(row['user_id']) ?? '',
    role: asText(row['role']),
    status: asText(row['status']),
    createdAt: asDate(row['created_at']),
    removedAt: asDate(row['removed_at']),
  );

  final String id;
  final String familyId;
  final String userId;
  final String? role;
  final String? status;
  final DateTime? createdAt;
  final DateTime? removedAt;

  bool get isActive => status == 'active';

  FamilyRole? get familyRole => FamilyRole.fromWire(role);
  FamilyMemberStatus? get memberStatus => FamilyMemberStatus.fromWire(status);
}

/// `public.child_contact_ids` — the canonical Child ID, `^PC[23456789ABC…]{8}$`,
/// assigned once per child and never regenerated.
final class ChildContactId {
  const ChildContactId({
    required this.childUserId,
    required this.contactId,
    required this.createdAt,
    this.rotatedAt,
  });

  factory ChildContactId.fromRow(Map<String, Object?> row) => ChildContactId(
    childUserId: asText(row['child_user_id']) ?? '',
    contactId: asText(row['contact_id']) ?? '',
    createdAt: asDate(row['created_at']) ?? DateTime.utc(1970),
    rotatedAt: asDate(row['rotated_at']),
  );

  final String childUserId;
  final String contactId;
  final DateTime createdAt;
  final DateTime? rotatedAt;

  Map<String, Object?> toRow() => {
    'child_user_id': childUserId,
    'contact_id': contactId,
  };
}
