import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/remote_sessions/data/session_detail_models.dart';
import 'package:haven_app/features/remote_sessions/data/session_gaps.dart';
import 'package:haven_app/features/remote_sessions/data/sessions_models.dart';
import 'package:haven_app/features/remote_sessions/data/sessions_repository.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// Fixtures shaped like `public.remote_sessions` as captured: the seventeen
/// columns of `docs/stage2/migrations/A3-staging-load-v1.sql:309-326`, with
/// `kind` from its CHECK (`:481`), `status` from its CHECK (`:483`) and
/// `expires_at` filled because a `requested` row must carry one (`:482`).
Map<String, Object?> sessionRow(
  String id, {
  String deviceId = 'd1',
  String parentUserId = 'u1',
  String childUserId = 'u2',
  String kind = 'video',
  String status = 'requested',
  String requestedAt = '2026-11-01T09:00:00.000Z',
  String createdAt = '2026-11-01T09:00:00.000Z',
  bool consentRecorded = true,
  String? acceptedAt,
  String? startedAt,
  String? endedAt,
  String? expiresAt = '2026-11-01T09:10:00.000Z',
  String? endedBy,
  String? endedReason,
  String? sessionNonce,
}) => {
  'id': id,
  'family_id': 'f1',
  'device_id': deviceId,
  'parent_user_id': parentUserId,
  'child_user_id': childUserId,
  'kind': kind,
  'status': status,
  'requested_at': requestedAt,
  'accepted_at': acceptedAt,
  'started_at': startedAt,
  'ended_at': endedAt,
  'expires_at': status == 'requested' ? expiresAt : null,
  'ended_by': endedBy,
  'ended_reason': endedReason,
  'consent_recorded': consentRecorded,
  'session_nonce': sessionNonce,
  'created_at': createdAt,
};

/// A `webrtc_signals` row: the seven columns of `sql:374-381`. `sequence` has no
/// default, so a fixture supplies one the way a writer would have to.
Map<String, Object?> signalRow(
  String id, {
  String sessionId = 's1',
  String fromUserId = 'u1',
  String kind = 'offer',
  int sequence = 1,
  Map<String, Object?> payload = const {'opaque': true},
  String createdAt = '2026-11-01T09:00:05.000Z',
}) => {
  'id': id,
  'session_id': sessionId,
  'from_user_id': fromUserId,
  'kind': kind,
  'payload': payload,
  'created_at': createdAt,
  'sequence': sequence,
};

/// The tables the session reads touch. `devices` is absent on purpose: the lane
/// that would name a session's device is F6 and the fake refuses it.
Map<String, List<Map<String, Object?>>> sessionTables({
  List<Map<String, Object?>> sessions = const [],
  List<Map<String, Object?>> signals = const [],
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
  TableName.remoteSessions: sessions,
  TableName.webrtcSignals: signals,
};

SessionLine sessionLine({
  String? deviceName,
  String id = 's1',
  String kind = 'video',
  String status = 'requested',
  bool consentRecorded = true,
  String? endedReason,
}) => SessionLine(
  RemoteSession(
    id: id,
    familyId: 'f1',
    deviceId: 'd1',
    parentUserId: 'u1',
    childUserId: 'u2',
    kind: kind,
    status: status,
    requestedAt: DateTime.parse('2026-11-01T09:00:00.000Z'),
    consentRecorded: consentRecorded,
    createdAt: DateTime.parse('2026-11-01T09:00:00.000Z'),
    endedReason: endedReason,
  ),
  deviceName: deviceName,
);

SessionBoard sessionBoard({
  List<SessionLine> lines = const [],
  BlockedFailure? deviceGap,
}) => SessionBoard(
  familyId: 'f1',
  lines: lines,
  startGap: SessionGaps.startGap,
  mediaGap: SessionGaps.mediaGap,
  deviceGap: deviceGap,
);

/// The session lane's answers. Nothing seeded is the refusal path, so a test that
/// forgets to seed cannot pass by reading a fabricated empty list.
class FakeSessionsRepository implements SessionsRepository {
  FakeSessionsRepository({
    this.board,
    this.details = const {},
    this.noFamily = false,
    this.failWith,
  });

  SessionBoard? board;

  /// The records this fake can answer for, keyed by id.
  Map<String, SessionDetail> details;
  bool noFamily;
  HavenFailure? failWith;

  int loadCount = 0;
  int detailCount = 0;
  String? lastSessionId;

  @override
  Future<Result<SessionBoard?>> load() async {
    loadCount++;
    final HavenFailure? failure = failWith;
    if (failure != null) return Err<SessionBoard?>(failure);
    if (noFamily) return const Ok<SessionBoard?>(null);
    final SessionBoard? read = board;
    return read == null
        ? blocked<SessionBoard?>('fake: no session read seeded')
        : Ok<SessionBoard?>(read);
  }

  @override
  Future<Result<SessionDetail?>> loadDetail(String sessionId) async {
    detailCount++;
    lastSessionId = sessionId;
    final HavenFailure? failure = failWith;
    if (failure != null) return Err<SessionDetail?>(failure);
    if (noFamily) return const Ok<SessionDetail?>(null);
    if (details.isEmpty) {
      return blocked<SessionDetail?>('fake: no session record seeded');
    }
    final SessionDetail? found = details[sessionId];
    return found == null
        ? const Err<SessionDetail?>(
            ValidationFailure(
              'fake: no record this account can read',
              field: 'session',
            ),
          )
        : Ok<SessionDetail?>(found);
  }
}

/// A detail board built from the fixture helpers.
SessionDetail sessionDetail({
  SessionLine? record,
  List<SignalLine> signals = const [],
  BlockedFailure? deviceGap,
}) => SessionDetail(
  familyId: 'f1',
  line: record ?? sessionLine(),
  signals: signals,
  signalGap: SessionGaps.signalGap,
  mediaGap: SessionGaps.mediaGap,
  deviceGap: deviceGap,
);

/// One signalling row, carrying the attribution the repository would give it.
SignalLine signalLine({String fromUserId = 'u1', String kind = 'offer'}) {
  final WebrtcSignal signal = WebrtcSignal.fromRow(
    signalRow('g1', fromUserId: fromUserId, kind: kind),
  );
  return SignalLine(signal, fromCaller: fromUserId == 'u1');
}
