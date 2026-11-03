import 'enums_sessions.dart';
import 'json_utils.dart';

/// `public.remote_sessions` — one requested session and its whole lifecycle.
final class RemoteSession {
  const RemoteSession({
    required this.id,
    required this.familyId,
    required this.deviceId,
    required this.parentUserId,
    required this.childUserId,
    required this.kind,
    required this.status,
    required this.requestedAt,
    required this.consentRecorded,
    required this.createdAt,
    this.acceptedAt,
    this.startedAt,
    this.endedAt,
    this.expiresAt,
    this.endedBy,
    this.endedReason,
    this.sessionNonce,
  });

  factory RemoteSession.fromRow(Map<String, Object?> row) => RemoteSession(
    id: asText(row['id']) ?? '',
    familyId: asText(row['family_id']) ?? '',
    deviceId: asText(row['device_id']) ?? '',
    parentUserId: asText(row['parent_user_id']) ?? '',
    childUserId: asText(row['child_user_id']) ?? '',
    kind: asText(row['kind']) ?? '',
    status: asText(row['status']) ?? '',
    requestedAt: asDate(row['requested_at']) ?? DateTime.utc(1970),
    acceptedAt: asDate(row['accepted_at']),
    startedAt: asDate(row['started_at']),
    endedAt: asDate(row['ended_at']),
    expiresAt: asDate(row['expires_at']),
    endedBy: asText(row['ended_by']),
    endedReason: asText(row['ended_reason']),
    consentRecorded: asBool(row['consent_recorded']) ?? false,
    sessionNonce: asText(row['session_nonce']),
    createdAt: asDate(row['created_at']) ?? DateTime.utc(1970),
  );

  final String id;
  final String familyId;
  final String deviceId;
  final String parentUserId;
  final String childUserId;
  final String kind;
  final String status;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? expiresAt;
  final String? endedBy;
  final String? endedReason;
  final bool consentRecorded;
  final String? sessionNonce;
  final DateTime createdAt;

  SessionStatus? get sessionStatus => SessionStatus.fromWire(status);
  SessionKind? get sessionKind => SessionKind.fromWire(kind);

  bool get isLive =>
      sessionStatus == SessionStatus.active ||
      sessionStatus == SessionStatus.accepted;
  bool get isClosed =>
      sessionStatus == SessionStatus.ended ||
      sessionStatus == SessionStatus.expired ||
      sessionStatus == SessionStatus.failed ||
      sessionStatus == SessionStatus.declined;

  /// Consent is recorded as one boolean. There is no consent version or
  /// withdrawal timestamp in the captured schema, so nothing claims more.
  bool get mayConnect => isLive && consentRecorded;
}

/// `public.webrtc_signals` — SDP/ICE transport rows, not a record of anything.
/// Retention is documented as ≤ 1 hour and deleted at session end
/// (`docs/stage1/03-data-model.md:85`).
final class WebrtcSignal {
  const WebrtcSignal({
    required this.id,
    required this.sessionId,
    required this.fromUserId,
    required this.kind,
    required this.payload,
    required this.createdAt,
    required this.sequence,
  });

  factory WebrtcSignal.fromRow(Map<String, Object?> row) => WebrtcSignal(
    id: asText(row['id']) ?? '',
    sessionId: asText(row['session_id']) ?? '',
    fromUserId: asText(row['from_user_id']) ?? '',
    kind: asText(row['kind']) ?? '',
    payload: asMap(row['payload']),
    createdAt: asDate(row['created_at']) ?? DateTime.utc(1970),
    sequence: asInt(row['sequence']) ?? 0,
  );

  final String id;
  final String sessionId;
  final String fromUserId;
  final String kind;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final int sequence;

  SignalKind? get signalKind => SignalKind.fromWire(kind);

  Map<String, Object?> toRow() => {
    'session_id': sessionId,
    'from_user_id': fromUserId,
    'kind': kind,
    'payload': payload,
    'sequence': sequence,
  };
}
