import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'sessions_models.dart';

/// One `webrtc_signals` row.
///
/// These are transport rows, not a record of anything: the plan in
/// `docs/stage1/03-data-model.md:85` keeps them under an hour and deletes them
/// when the session ends. So a count here is a count of what the read returned
/// at a moment, and a payload is reported as existing rather than shown — the
/// only thing captured about it is a size cap (`sql:497`).
final class SignalLine {
  const SignalLine(this.signal, {this.fromCaller = false});

  final WebrtcSignal signal;

  /// Whether this account wrote the row. `webrtc_signals_insert_participant`
  /// requires `from_user_id = auth.uid()` (`sql:761`), so a row the caller sent
  /// is provable; anything else is the other side's.
  final bool fromCaller;

  String get what {
    final SignalKind? kind = signal.signalKind;
    if (kind == null) {
      return 'A signalling row this build cannot classify (${signal.kind})';
    }
    return kind.label;
  }

  String get side => fromCaller
      ? 'this account sent it'
      : 'a row the record attributes to another account';

  /// `sequence` is `bigint NOT NULL` with no default (`sql:380`), so the number
  /// belongs to whoever wrote the row; nothing captured says what it orders.
  String get order => 'numbered ${signal.sequence} by its writer';

  String get contents =>
      '${signal.payload.length} '
      '${signal.payload.length == 1 ? 'item' : 'items'} in its payload, not '
      'shown here';

  String get when => 'written ${signal.createdAt.toUtc().toIso8601String()}';

  String get line => '$what · $side · $order · $contents · $when';
}

/// One session and the signalling rows that the read returned for it.
final class SessionDetail {
  const SessionDetail({
    required this.familyId,
    required this.line,
    required this.signals,
    required this.signalGap,
    required this.mediaGap,
    this.deviceGap,
  });

  final String familyId;
  final SessionLine line;
  final List<SignalLine> signals;

  /// Writing a signalling row is the one table grant a client does hold
  /// (`04-rls-matrix.md:159`), and it is still not a usable lane: no peer exists
  /// to produce an offer, and nothing captured says how `sequence` is allocated.
  final BlockedFailure signalGap;

  /// The peer itself, behind the interface this feature refuses to fake.
  final BlockedFailure mediaGap;

  final BlockedFailure? deviceGap;

  bool get hasSignals => signals.isNotEmpty;

  /// A page size, not the whole buffer.
  static const int window = 40;

  String get counted =>
      '${signals.length} signalling ${signals.length == 1 ? 'row' : 'rows'} '
      'read — the newest $window the backend would give for this session.';

  String get bufferLine =>
      'These rows are a transport buffer, not a history: the plan keeps them '
      'for under an hour and deletes them when the session ends. So this list '
      'shows what was in the buffer when the screen read it.';

  /// The one sentence that keeps a session row from being read as a connection.
  String get stateLine =>
      '${line.state} The record shows ${signals.length} '
      '${signals.length == 1 ? 'row' : 'rows'} passing through it, which is not '
      'the same as anything reaching a phone.';
}
