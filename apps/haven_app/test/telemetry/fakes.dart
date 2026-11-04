import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/telemetry/data/telemetry_models.dart';
import 'package:haven_app/features/telemetry/data/telemetry_repository.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// Fixtures shaped like `public.audit_logs` as captured: the nine columns of
/// `docs/stage2/migrations/A3-staging-load-v1.sql:144-154`. `event_type` is free
/// text of 1..80 (`:433`) and `metadata` only has to be a JSON object (`:434`),
/// so a fixture uses an unlisted event type rather than a made-up enum.
Map<String, Object?> auditRow(
  String id, {
  String? deviceId = 'd1',
  String eventType = 'policy.version.written',
  String? targetType = 'device',
  String? targetId,
  String? actorUserId = 'u1',
  Map<String, Object?> metadata = const {'version': 4},
  String createdAt = '2026-11-01T09:00:00.000Z',
}) => {
  'id': id,
  'family_id': 'f1',
  'actor_user_id': actorUserId,
  'device_id': deviceId,
  'event_type': eventType,
  'target_type': targetType,
  'target_id': targetId,
  'metadata': metadata,
  'created_at': createdAt,
};

/// The tables the trail read touches. `devices` is absent: the lane that would
/// name a device or show a last-seen time is F6, and the fake refuses it.
Map<String, List<Map<String, Object?>>> trailTables({
  List<Map<String, Object?>> rows = const [],
}) => {
  TableName.familyMembers: const [
    {
      'id': 'm-u1',
      'family_id': 'f1',
      'user_id': 'u1',
      'role': 'parent',
      'status': 'active',
      'created_at': '2026-01-05T10:00:00.000Z',
    },
  ],
  TableName.auditLogs: rows,
};

AuditLine auditLine({
  String? deviceName,
  String? deviceId = 'd1',
  String eventType = 'policy.version.written',
  String? targetType = 'device',
  Map<String, Object?> metadata = const {'version': 4},
  String createdAt = '2026-11-01T09:00:00.000Z',
}) => AuditLine(
  AuditLog(
    id: 'a-1',
    familyId: 'f1',
    actorUserId: 'u1',
    deviceId: deviceId,
    eventType: eventType,
    targetType: targetType,
    targetId: deviceId,
    metadata: metadata,
    createdAt: DateTime.parse(createdAt),
  ),
  deviceName: deviceName,
);

TelemetryBoard trailBoard({
  List<AuditLine> lines = const [],
  BlockedFailure? deviceGap,
  String? deviceId,
}) => TelemetryBoard(
  familyId: 'f1',
  deviceId: deviceId,
  lines: lines,
  offlineGap: HavenTelemetryRepository.offlineGap,
  deviceGap: deviceGap,
);

/// The trail's answers. Nothing seeded is the refusal path, so a test that forgets
/// to seed cannot pass by reading a fabricated empty log.
class FakeTelemetryRepository implements TelemetryRepository {
  FakeTelemetryRepository({this.board, this.noFamily = false, this.failWith});

  TelemetryBoard? board;
  bool noFamily;
  HavenFailure? failWith;

  int loadCount = 0;
  String? lastDeviceId;

  @override
  Future<Result<TelemetryBoard?>> load({String? deviceId}) async {
    loadCount++;
    lastDeviceId = deviceId;
    final HavenFailure? failure = failWith;
    if (failure != null) return Err<TelemetryBoard?>(failure);
    if (noFamily) return const Ok<TelemetryBoard?>(null);
    final TelemetryBoard? read = board;
    return read == null
        ? blocked<TelemetryBoard?>('fake: no trail read seeded')
        : Ok<TelemetryBoard?>(read);
  }
}
