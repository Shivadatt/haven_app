import 'json_utils.dart';

/// `public.usage_daily` — app usage per device, per day, per package.
final class UsageDaily {
  const UsageDaily({
    required this.id,
    required this.deviceId,
    required this.familyId,
    required this.day,
    required this.packageName,
    required this.appLabel,
    required this.totalMs,
    required this.uploadedAt,
    required this.source,
    this.lastUsedAt,
  });

  factory UsageDaily.fromRow(Map<String, Object?> row) => UsageDaily(
    id: asText(row['id']) ?? '',
    deviceId: asText(row['device_id']) ?? '',
    familyId: asText(row['family_id']) ?? '',
    day: asDate(row['day']),
    packageName: asText(row['package_name']) ?? '',
    appLabel: asText(row['app_label']) ?? '',
    totalMs: asInt(row['total_ms']) ?? 0,
    lastUsedAt: asDate(row['last_used_at']),
    uploadedAt: asDate(row['uploaded_at']) ?? DateTime.utc(1970),
    source: asText(row['source']) ?? 'unknown',
  );

  final String id;
  final String deviceId;
  final String familyId;

  /// `day` is a `date`; captured as a timestamp string, so it can be null if a
  /// row arrives without it rather than defaulting silently.
  final DateTime? day;
  final String packageName;
  final String appLabel;
  final int totalMs;
  final DateTime? lastUsedAt;
  final DateTime uploadedAt;

  /// No CHECK constraint on this column, so it stays a string: the report says
  /// what arrived, not what we assume it means.
  final String source;
}

/// `public.audit_logs` — who did what. `event_type` is free text (1..80), so it
/// stays a string and is never mapped onto an invented enum.
final class AuditLog {
  const AuditLog({
    required this.id,
    required this.eventType,
    required this.metadata,
    required this.createdAt,
    this.familyId,
    this.actorUserId,
    this.deviceId,
    this.targetType,
    this.targetId,
  });

  factory AuditLog.fromRow(Map<String, Object?> row) => AuditLog(
    id: asText(row['id']) ?? '',
    familyId: asText(row['family_id']),
    actorUserId: asText(row['actor_user_id']),
    deviceId: asText(row['device_id']),
    eventType: asText(row['event_type']) ?? '',
    targetType: asText(row['target_type']),
    targetId: asText(row['target_id']),
    metadata: asMap(row['metadata']),
    createdAt: asDate(row['created_at']) ?? DateTime.utc(1970),
  );

  final String id;
  final String? familyId;
  final String? actorUserId;
  final String? deviceId;
  final String eventType;
  final String? targetType;
  final String? targetId;
  final Map<String, Object?> metadata;
  final DateTime createdAt;
}
