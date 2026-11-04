import 'package:haven_core/haven_core.dart';

import '../../../core/errors/captured_gaps.dart';

/// The three lanes beside a session record, and the evidence each one is closed
/// for.
///
/// They live in one file because the same sentences are read by the repository
/// that carries them on a board, by the media peer that refuses, and by the
/// screens that render them. Paraphrasing in three places is how a refusal turns
/// into a promise.
abstract final class SessionGaps {
  static const String startMissing =
      '`remote_sessions` gives `authenticated` SELECT and nothing else — '
      'INSERT, UPDATE and DELETE belong to `service_role` alone '
      '(04-rls-matrix.md:139-141, A3-staging-load-v1.sql:908-909); the RPC '
      'that would create a request, `request_remote_session(p_device_id, '
      'p_parent_user_id, p_kind)`, and the one that would retire a stale '
      'request, `expire_stale_sessions()`, sit behind the same wall as every '
      'other one — ${CapturedGaps.rpcLaneMissing} — and the `remote-session` '
      'Edge Function that would hold a service role is not deployed';

  static const String mediaMissing =
      'the capture holds no TURN server, no credential lifecycle and no SDP or '
      'ICE handling (docs/stage1/03-data-model.md:42), and media was declared '
      'out of scope in docs/stage1/00-status-register.md X2 — what exists is '
      'the shape of the signalling table, not a way to connect through it';

  static const String signalMissing =
      '`webrtc_signals` is the one table `authenticated` may insert into '
      '(04-rls-matrix.md:159, A3-staging-load-v1.sql:917), but a row still '
      'cannot be written from here without guessing: `sequence` is `bigint NOT '
      'NULL` with no default and nothing captured says how it is allocated '
      '(`:380`), `payload` is bounded only by a 16384-byte cap with no '
      'documented keys (`:497`), and there is no peer to produce an offer';

  /// Built once so the board, the peer and the screen hand round the very same
  /// instance — a refusal that is rebuilt per read cannot be recognised as the
  /// one already shown elsewhere.
  static final BlockedFailure startGap = BlockedFailure(
    'Haven cannot ask for, answer or retire a session in this build yet.',
    missing: startMissing,
    detail: 'BLOCKED — SPECIFICATION REQUIRED: $startMissing',
  );

  static final BlockedFailure mediaGap = BlockedFailure(
    'Haven cannot open the audio or video path in this build yet.',
    missing: mediaMissing,
    detail: 'BLOCKED — SPECIFICATION REQUIRED: $mediaMissing',
  );

  static final BlockedFailure signalGap = BlockedFailure(
    'Haven cannot send a signalling row for a session in this build yet.',
    missing: signalMissing,
    detail: 'BLOCKED — SPECIFICATION REQUIRED: $signalMissing',
  );
}
