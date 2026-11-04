import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

/// One `remote_sessions` row: a request, the timestamps around it, and the one
/// boolean that says whether consent was recorded.
///
/// This line reports what the record says. It cannot report what happened on the
/// phone, because this build carries no audio or video path at all — that refusal
/// lives beside the list, not inside a row that would read as proof.
final class SessionLine {
  const SessionLine(this.session, {this.deviceName});

  final RemoteSession session;

  /// The device the request named, when the device lane could be read.
  final String? deviceName;

  String get whose => deviceName ?? 'a device this build cannot name';

  /// `kind` is bound to `audio` or `video` by `remote_sessions_kind_check`
  /// (`A3-staging-load-v1.sql:481`), so anything else is echoed rather than
  /// sorted into a category Haven invented.
  String get what {
    final SessionKind? kind = session.sessionKind;
    if (kind == null) {
      return 'A session this build cannot classify (${session.kind})';
    }
    return kind == SessionKind.video
        ? 'A request for a video session'
        : 'A request for an audio session';
  }

  String get statusLabel => session.sessionStatus?.label ?? 'Unrecognised';

  /// The status column in the record's own terms. `active` is what a row says,
  /// not what this app observed.
  String get state => switch (session.sessionStatus) {
    SessionStatus.requested => 'Asked for; the device side has not answered',
    SessionStatus.accepted => 'Answered; the record has not moved past that',
    SessionStatus.active =>
      'The record says it is running. Nothing here carries sound or picture.',
    SessionStatus.declined => 'The record says the request was declined',
    SessionStatus.ended => 'The record says it ended',
    SessionStatus.expired =>
      'The record says it ran out the time a request may wait',
    SessionStatus.failed => 'The record says it failed',
    null => 'A state this build does not recognise (${session.status})',
  };

  /// Consent is a single boolean with no version, scope or withdrawal beside it
  /// (`docs/stage1/03-data-model.md:176`), so this says only that a row carries
  /// the mark — never what was agreed to.
  String get consent => session.consentRecorded
      ? 'Consent is recorded as given on this row'
      : 'Nothing on this row records consent';

  bool get liveWithoutConsent => session.isLive && !session.consentRecorded;

  String get when => 'requested ${_stamp(session.requestedAt)}';

  /// A `requested` row must carry `expires_at` —
  /// `remote_sessions_pending_expiry_check` (`sql:482`).
  String? get until => session.expiresAt == null
      ? null
      : 'waits until ${_stamp(session.expiresAt!)}';

  String? get opened => session.startedAt == null
      ? null
      : 'started ${_stamp(session.startedAt!)}';

  String? get closed =>
      session.endedAt == null ? null : 'ended ${_stamp(session.endedAt!)}';

  /// `ended_by` is a user id and the profile lane cannot name it, so the row is
  /// reported as having an author without inventing who.
  String? get whoClosed =>
      session.endedBy == null ? null : 'the record names who ended it';

  /// `ended_reason` is free text up to 200 characters (`sql:480`) written by
  /// whoever closed the session, so it is shown as it arrived.
  String? get whyClosed => session.endedReason;

  /// The row's own timeline, in the order the columns were filled.
  String get trail => <String>[
    when,
    if (session.acceptedAt != null) 'accepted ${_stamp(session.acceptedAt!)}',
    ?opened,
    ?closed,
    ?until,
    ?whoClosed,
  ].join(' · ');

  static String _stamp(DateTime instant) => instant.toUtc().toIso8601String();
}

/// The sessions this account may read, and the two lanes that are closed.
final class SessionBoard {
  const SessionBoard({
    required this.familyId,
    required this.lines,
    required this.startGap,
    required this.mediaGap,
    this.deviceGap,
  });

  final String familyId;
  final List<SessionLine> lines;

  /// Asking for a session, answering one, and retiring a stale request are one
  /// closed lane: no client role may write this table and the two RPCs that would
  /// are held by `postgres` and `service_role`.
  final BlockedFailure startGap;

  /// The peer itself. Signalling rows are readable, but nothing in the evidence
  /// describes how a connection is made, so no screen claims one is possible.
  final BlockedFailure mediaGap;

  /// The refusal that would otherwise name each session's device.
  final BlockedFailure? deviceGap;

  bool get hasLines => lines.isNotEmpty;

  /// A page size, not a history. Session metadata is said to be retained 90 days
  /// (`docs/stage1/03-data-model.md:86`); that is a plan, not a captured rule.
  static const int window = 20;

  String get counted =>
      '${lines.length} session ${lines.length == 1 ? 'record' : 'records'} read '
      '— the newest $window the backend would give for this family.';

  int get liveCount => lines.where((SessionLine l) => l.session.isLive).length;

  String get liveLine =>
      '$liveCount of ${lines.length} are still open in the record.';

  int get unconsentedLiveCount =>
      lines.where((SessionLine l) => l.liveWithoutConsent).length;

  /// The consent-visible rule: a row that is open without a consent mark is
  /// named here rather than left in the list to look like any other session.
  String get consentLine => unconsentedLiveCount == 0
      ? 'Every open row in this list carries a consent mark.'
      : '$unconsentedLiveCount open ${unconsentedLiveCount == 1 ? 'row carries' : 'rows carry'} '
            'no consent mark. An open session without consent is not a session '
            'Haven would connect to.';
}
