import 'enums_commands.dart';
import 'enums_identity.dart';
import 'json_utils.dart';

/// `public.device_commands` — a parent-issued instruction and its delivery trail.
final class DeviceCommand {
  const DeviceCommand({
    required this.id,
    required this.deviceId,
    required this.familyId,
    required this.payload,
    required this.idempotencyKey,
    required this.createdAt,
    required this.expiresAt,
    required this.attempts,
    this.type,
    this.status,
    this.createdBy,
    this.deliveredAt,
    this.ackedAt,
    this.result,
    this.errorMessage,
  });

  factory DeviceCommand.fromRow(Map<String, Object?> row) => DeviceCommand(
    id: asText(row['id']) ?? '',
    deviceId: asText(row['device_id']) ?? '',
    familyId: asText(row['family_id']) ?? '',
    type: asText(row['type']),
    payload: asMap(row['payload']),
    status: asText(row['status']),
    idempotencyKey: asText(row['idempotency_key']) ?? '',
    createdBy: asText(row['created_by']),
    createdAt: asDate(row['created_at']) ?? DateTime.utc(1970),
    expiresAt: asDate(row['expires_at']),
    deliveredAt: asDate(row['delivered_at']),
    ackedAt: asDate(row['acked_at']),
    result: row['result'] == null ? null : asMap(row['result']),
    errorMessage: asText(row['error_message']),
    attempts: asInt(row['attempts']) ?? 0,
  );

  final String id;
  final String deviceId;
  final String familyId;
  final String? type;
  final Map<String, Object?> payload;
  final String? status;
  final String idempotencyKey;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? deliveredAt;
  final DateTime? ackedAt;
  final Map<String, Object?>? result;
  final String? errorMessage;
  final int attempts;

  CommandType? get commandType => CommandType.fromWire(type);
  CommandStatus? get commandStatus => CommandStatus.fromWire(status);
  bool get isSettled =>
      commandStatus == CommandStatus.succeeded ||
      commandStatus == CommandStatus.failed ||
      commandStatus == CommandStatus.expired;

  /// The device answered. Nothing here infers success from a silent device.
  bool get isAcknowledged => ackedAt != null;
}

/// `public.device_pairing_tokens` — the hashed short code or invite.
final class DevicePairingToken {
  const DevicePairingToken({
    required this.id,
    required this.childUserId,
    required this.codeHash,
    required this.expiresAt,
    required this.status,
    required this.attempts,
    required this.maxAttempts,
    required this.createdAt,
    this.redeemedAt,
    this.redeemedBy,
    this.createdBy,
    this.purpose,
  });

  factory DevicePairingToken.fromRow(Map<String, Object?> row) =>
      DevicePairingToken(
        id: asText(row['id']) ?? '',
        childUserId: asText(row['child_user_id']) ?? '',
        codeHash: asText(row['code_hash']) ?? '',
        expiresAt: asDate(row['expires_at']) ?? DateTime.utc(1970),
        status: asText(row['status']),
        attempts: asInt(row['attempts']) ?? 0,
        maxAttempts: asInt(row['max_attempts']) ?? 1,
        createdAt: asDate(row['created_at']) ?? DateTime.utc(1970),
        redeemedAt: asDate(row['redeemed_at']),
        redeemedBy: asText(row['redeemed_by']),
        createdBy: asText(row['created_by']),
        purpose: asText(row['purpose']),
      );

  final String id;
  final String childUserId;
  final String codeHash;
  final DateTime expiresAt;
  final String? status;
  final int attempts;
  final int maxAttempts;
  final DateTime createdAt;
  final DateTime? redeemedAt;
  final String? redeemedBy;
  final String? createdBy;
  final String? purpose;

  PairingTokenStatus? get tokenStatus => PairingTokenStatus.fromWire(status);
  PairingTokenPurpose? get tokenPurpose =>
      PairingTokenPurpose.fromWire(purpose);

  /// Exhausted codes are unusable even while `status` still says `active`.
  bool get hasAttemptsLeft => attempts < maxAttempts;
}

/// `public.pairing_requests` — the child-side approval step.
final class PairingRequest {
  const PairingRequest({
    required this.id,
    required this.tokenId,
    required this.familyId,
    required this.parentUserId,
    required this.childUserId,
    required this.createdAt,
    required this.expiresAt,
    this.status,
    this.respondedAt,
  });

  factory PairingRequest.fromRow(Map<String, Object?> row) => PairingRequest(
    id: asText(row['id']) ?? '',
    tokenId: asText(row['token_id']) ?? '',
    familyId: asText(row['family_id']) ?? '',
    parentUserId: asText(row['parent_user_id']) ?? '',
    childUserId: asText(row['child_user_id']) ?? '',
    status: asText(row['status']),
    createdAt: asDate(row['created_at']) ?? DateTime.utc(1970),
    expiresAt: asDate(row['expires_at']) ?? DateTime.utc(1970),
    respondedAt: asDate(row['responded_at']),
  );

  final String id;
  final String tokenId;
  final String familyId;
  final String parentUserId;
  final String childUserId;
  final String? status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? respondedAt;

  PairingRequestStatus? get requestStatus =>
      PairingRequestStatus.fromWire(status);
  bool get isPending =>
      requestStatus == PairingRequestStatus.pendingChild && respondedAt == null;
}

/// `public.pairing_attempts` — the security log of code guessing.
final class PairingAttempt {
  const PairingAttempt({
    required this.id,
    required this.parentUserId,
    required this.codeHash,
    required this.attemptedAt,
    required this.success,
  });

  factory PairingAttempt.fromRow(Map<String, Object?> row) => PairingAttempt(
    id: asText(row['id']) ?? '',
    parentUserId: asText(row['parent_user_id']) ?? '',
    codeHash: asText(row['code_hash']) ?? '',
    attemptedAt: asDate(row['attempted_at']) ?? DateTime.utc(1970),
    success: asBool(row['success']) ?? false,
  );

  final String id;
  final String parentUserId;
  final String codeHash;
  final DateTime attemptedAt;
  final bool success;
}
