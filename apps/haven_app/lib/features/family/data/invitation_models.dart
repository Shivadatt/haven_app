import 'package:haven_models/haven_models.dart';

/// An invitation record stored locally in offline mode.
final class FamilyInvitation {
  const FamilyInvitation({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.email,
    required this.role,
    required this.status,
    this.createdAt,
  });

  factory FamilyInvitation.fromRow({
    required Map<String, Object?> memberRow,
    Map<String, Object?>? profileRow,
  }) => FamilyInvitation(
    id: asText(memberRow['id']) ?? '',
    familyId: asText(memberRow['family_id']) ?? '',
    userId: asText(memberRow['user_id']) ?? '',
    email: asText(profileRow?['email']) ?? asText(memberRow['user_id']) ?? '',
    role: asText(memberRow['role']) ?? 'parent',
    status: asText(memberRow['status']) ?? 'invited',
    createdAt: asDate(memberRow['created_at']),
  );

  final String id;
  final String familyId;
  final String userId;
  final String email;
  final String role;
  final String status;
  final DateTime? createdAt;

  bool get isPending => status == 'invited';
}
