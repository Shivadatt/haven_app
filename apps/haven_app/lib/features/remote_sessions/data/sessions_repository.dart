import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../child_devices/data/devices_repository.dart';
import '../../family/data/family_scope.dart';
import 'session_detail_models.dart';
import 'session_gaps.dart';
import 'sessions_models.dart';

/// The session records this account may read.
///
/// `remote_sessions` has a SELECT policy and grant for a parent, the child named
/// in the row, or a family parent (`docs/stage1/04-rls-matrix.md:53`, `:138`,
/// `A3-staging-load-v1.sql:908`), so the lifecycle is readable. Nothing a client
/// holds can move a row: the write grants are `service_role` only and both RPCs
/// that would change one are closed, which is why this interface reads and states
/// the two refusals instead of offering a button that could only be turned down.
abstract interface class SessionsRepository {
  /// Null means this account has no family yet, which the screen routes to setup.
  Future<Result<SessionBoard?>> load();

  /// The session and the signalling rows the read returned for it.
  ///
  /// A row this account is not a participant of is not returned by the backend
  /// and is reported as unreadable, not as a session that never existed.
  Future<Result<SessionDetail?>> loadDetail(String sessionId);
}

final class HavenSessionsRepository implements SessionsRepository {
  HavenSessionsRepository({
    required FamilyScopeReader Function() scope,
    required RowReader Function() rows,
    required DevicesRepository Function() devices,
  }) : _scope = scope,
       _rows = rows,
       _devices = devices;

  /// Providers, not values: `HavenBackend.install()` is asynchronous.
  final FamilyScopeReader Function() _scope;
  final RowReader Function() _rows;
  final DevicesRepository Function() _devices;

  @override
  Future<Result<SessionBoard?>> load() async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) {
      final HavenFailure why = scope.failureOrNull!;
      return FamilyScopeReader.isMissingFamily(why)
          ? const Ok<SessionBoard?>(null)
          : Err<SessionBoard?>(why);
    }

    // Ordered on the captured index `remote_sessions_family_idx`
    // (family_id, requested_at DESC) — A3-staging-load-v1.sql:588.
    final Result<List<Map<String, Object?>>> rows = await _rows().rows(
      TableName.remoteSessions,
      eq: <String, Object?>{'family_id': mine.familyId},
      orderDesc: 'requested_at',
      limit: SessionBoard.window,
    );
    final HavenFailure? readFailure = rows.failureOrNull;
    if (readFailure != null) return Err<SessionBoard?>(readFailure);

    final (List<Device>? named, BlockedFailure? gap) = await _deviceLane();
    return Ok<SessionBoard?>(
      SessionBoard(
        familyId: mine.familyId,
        lines: _lines(rows.valueOrNull!, named),
        startGap: SessionGaps.startGap,
        mediaGap: SessionGaps.mediaGap,
        deviceGap: gap,
      ),
    );
  }

  @override
  Future<Result<SessionDetail?>> loadDetail(String sessionId) async {
    final Result<FamilyScope> scope = await _scope().resolve();
    final FamilyScope? mine = scope.valueOrNull;
    if (mine == null) {
      final HavenFailure why = scope.failureOrNull!;
      return FamilyScopeReader.isMissingFamily(why)
          ? const Ok<SessionDetail?>(null)
          : Err<SessionDetail?>(why);
    }

    // The family id always travels with the session id, so a value handed to the
    // route cannot reach another family's session even before the policy acts.
    final Result<Map<String, Object?>?> row = await _rows().first(
      TableName.remoteSessions,
      eq: <String, Object?>{'family_id': mine.familyId, 'id': sessionId},
    );
    final HavenFailure? readFailure = row.failureOrNull;
    if (readFailure != null) return Err<SessionDetail?>(readFailure);
    final Map<String, Object?>? found = row.valueOrNull;
    if (found == null) {
      return const Err<SessionDetail?>(
        ValidationFailure(
          'This session is not one this account can read. Either it was never '
          'asked for, or this account is not the parent or child named in it.',
          field: 'session',
        ),
      );
    }

    // `webrtc_signals` carries no family column, so this read is scoped by the
    // session id alone and relies on `webrtc_signals_select_participant`, which
    // returns nothing for an account that is not a participant (sql:773).
    final Result<List<Map<String, Object?>>> buffer = await _rows().rows(
      TableName.webrtcSignals,
      eq: <String, Object?>{'session_id': sessionId},
      orderDesc: 'created_at',
      limit: SessionDetail.window,
    );
    final HavenFailure? bufferFailure = buffer.failureOrNull;
    if (bufferFailure != null) return Err<SessionDetail?>(bufferFailure);

    final (List<Device>? named, BlockedFailure? gap) = await _deviceLane();
    final RemoteSession session = RemoteSession.fromRow(found);
    final String who = mine.session.userId;
    return Ok<SessionDetail?>(
      SessionDetail(
        familyId: mine.familyId,
        line: SessionLine(
          session,
          deviceName: named == null ? null : _nameOf(named, session.deviceId),
        ),
        signals: buffer.valueOrNull!
            .map((Map<String, Object?> raw) {
              final WebrtcSignal parsed = WebrtcSignal.fromRow(raw);
              return SignalLine(parsed, fromCaller: parsed.fromUserId == who);
            })
            .toList(growable: false),
        signalGap: SessionGaps.signalGap,
        mediaGap: SessionGaps.mediaGap,
        deviceGap: gap,
      ),
    );
  }

  /// The device lane is F6, so this answers with names or with the refusal that
  /// the screen carries in place of them — never with a silent fallback.
  Future<(List<Device>? named, BlockedFailure? gap)> _deviceLane() async {
    final Result<List<Device>> owners = await _devices().pairedDevices();
    final BlockedFailure? gap = owners.failureOrNull is BlockedFailure
        ? owners.failureOrNull as BlockedFailure
        : null;
    return (owners.valueOrNull, gap);
  }

  List<SessionLine> _lines(
    List<Map<String, Object?>> rows,
    List<Device>? named,
  ) => rows
      .map((Map<String, Object?> row) {
        final RemoteSession session = RemoteSession.fromRow(row);
        return SessionLine(
          session,
          deviceName: named == null ? null : _nameOf(named, session.deviceId),
        );
      })
      .toList(growable: false);

  static String? _nameOf(List<Device> devices, String id) {
    if (id.isEmpty) return null;
    for (final Device device in devices) {
      if (device.id == id) {
        return device.displayName.isEmpty ? null : device.displayName;
      }
    }
    return null;
  }
}
