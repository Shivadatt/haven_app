/// Argument records for the family, pairing and unlink RPCs captured in
/// `docs/stage1/evidence/g1-q7-20261029.json`.
///
/// Parameter names are exactly as captured (`p_...`). **Return types were never
/// captured for any of these functions**, so nothing here decodes a result.
library;

import 'json_utils.dart';

/// `create_family_with_owner(p_owner uuid, p_name text)`
final class CreateFamilyWithOwnerArgs {
  const CreateFamilyWithOwnerArgs({required this.owner, required this.name});

  final String owner;
  final String name;

  Map<String, Object?> toParams() => {'p_owner': owner, 'p_name': name};
}

/// `unlink_child(p_family_id uuid, p_child_user_id uuid, p_actor_user_id uuid)`
final class UnlinkChildArgs {
  const UnlinkChildArgs({
    required this.familyId,
    required this.childUserId,
    required this.actorUserId,
  });

  final String familyId;
  final String childUserId;
  final String actorUserId;

  Map<String, Object?> toParams() => {
    'p_family_id': familyId,
    'p_child_user_id': childUserId,
    'p_actor_user_id': actorUserId,
  };
}

/// `create_pairing_invite(p_child_user_id, p_family_id, p_parent_user_id, p_code_hash, p_expires_at)`
///
/// Only the hash is ever sent; a plaintext code has no place in this type.
final class CreatePairingInviteArgs {
  const CreatePairingInviteArgs({
    required this.childUserId,
    required this.familyId,
    required this.parentUserId,
    required this.codeHash,
    required this.expiresAt,
  });

  final String childUserId;
  final String familyId;
  final String parentUserId;
  final String codeHash;
  final DateTime expiresAt;

  Map<String, Object?> toParams() => {
    'p_child_user_id': childUserId,
    'p_family_id': familyId,
    'p_parent_user_id': parentUserId,
    'p_code_hash': codeHash,
    'p_expires_at': toJsonDate(expiresAt),
  };
}

/// `create_pairing_request(p_child_user_id, p_family_id, p_parent_user_id, p_token_id, p_expires_at)`
final class CreatePairingRequestArgs {
  const CreatePairingRequestArgs({
    required this.childUserId,
    required this.familyId,
    required this.parentUserId,
    required this.tokenId,
    required this.expiresAt,
  });

  final String childUserId;
  final String familyId;
  final String parentUserId;
  final String tokenId;
  final DateTime expiresAt;

  Map<String, Object?> toParams() => {
    'p_child_user_id': childUserId,
    'p_family_id': familyId,
    'p_parent_user_id': parentUserId,
    'p_token_id': tokenId,
    'p_expires_at': toJsonDate(expiresAt),
  };
}

/// `respond_pairing_request(p_request_id uuid, p_child_user_id uuid, p_approve boolean)`
final class RespondPairingRequestArgs {
  const RespondPairingRequestArgs({
    required this.requestId,
    required this.childUserId,
    required this.approve,
  });

  final String requestId;
  final String childUserId;
  final bool approve;

  Map<String, Object?> toParams() => {
    'p_request_id': requestId,
    'p_child_user_id': childUserId,
    'p_approve': approve,
  };
}

/// `apply_policy_version(p_device_id uuid, p_policy jsonb, p_actor uuid, p_idempotency_key text)`
///
/// `p_policy` is a `jsonb` document whose required keys are not captured
/// anywhere, so it stays an opaque map the caller assembled from the docs.
final class ApplyPolicyVersionArgs {
  const ApplyPolicyVersionArgs({
    required this.deviceId,
    required this.policy,
    required this.actor,
    required this.idempotencyKey,
  });

  final String deviceId;
  final Map<String, Object?> policy;
  final String actor;
  final String idempotencyKey;

  Map<String, Object?> toParams() => {
    'p_device_id': deviceId,
    'p_policy': policy,
    'p_actor': actor,
    'p_idempotency_key': idempotencyKey,
  };
}
