import 'package:haven_core/haven_core.dart';

import '../data/session_gaps.dart';

/// The peer that would carry audio or video for a session.
///
/// The contract splits this feature in two: the signalling rows and the session
/// lifecycle are evidenced and implementable, while the media path is not
/// (`docs/implementation/00-app-contract.md:104-107`). So the peer stays behind
/// an interface, and this build ships the one implementation the evidence allows.
abstract interface class SessionMediaPeer {
  /// Would open the connection for a session this account can read.
  Future<Result<void>> start(String sessionId);

  /// Would take the connection down again.
  Future<Result<void>> stop();

  /// Whether media is flowing. Nothing can make this true in this build, and no
  /// screen is allowed to render a session as heard or seen.
  bool get isCarrying;
}

/// The refusal, in one place, so a screen cannot paraphrase it into a promise.
///
/// A TURN server, its credentials and the SDP/ICE exchange around it appear
/// nowhere in the capture, and media was declared out of scope, so there is no
/// peer to negotiate with. This returns the same `BlockedFailure` the session
/// screens display, which is the point: the sentence a parent reads and the
/// sentence the code gives are the same sentence.
final class UnspecifiedMediaPeer implements SessionMediaPeer {
  const UnspecifiedMediaPeer();

  @override
  Future<Result<void>> start(String sessionId) =>
      _refuse('open the audio or video path for a session');

  @override
  Future<Result<void>> stop() => _refuse('take a session connection down');

  @override
  bool get isCarrying => false;

  static Future<Result<void>> _refuse(String what) async => blocked<void>(
    SessionGaps.mediaMissing,
    requirement: 'Haven cannot $what in this build yet.',
  );
}
