part 'registration_status_states.dart';

/// The registration states this child device can be in.
///
/// Phase 3 Stage 2 delivers the CONTRACT only. Decision D-5 keeps real
/// cross-device pairing BLOCKED (`STAGE_2_OWNER_DECISIONS.md` §3), so the only
/// implementation that can ever reach [RegistrationKind.registered] in this
/// build is the clearly labelled local DEMO lane
/// (`DemoRegistrationService`); the cross-device lane answers `blocked(...)`.
enum RegistrationKind {
  unregistered('unregistered'),
  demoPending('demoPending'),
  registered('registered'),
  rejected('rejected'),
  revoked('revoked');

  const RegistrationKind(this.wire);

  /// The persisted spelling. A stored `kind` this class does not know is
  /// malformed data — see `RegistrationCodec`.
  final String wire;

  static RegistrationKind? fromWire(String? raw) {
    for (final RegistrationKind kind in RegistrationKind.values) {
      if (kind.wire == raw) return kind;
    }
    return null;
  }
}

/// Why a registration attempt did not land. Split out because a screen must
/// tell "you typed it wrong" apart from "this build cannot pair at all".
enum RegistrationRejectReason {
  codeFormat('code-format', 'That code is not the shape this DEMO expects.'),
  codeExpired(
    'code-expired',
    'DEMO: the code timed out (5-minute simulated expiry).',
  ),
  codeMismatch('code-mismatch', 'DEMO: this device was never given that code.'),
  codeAlreadyUsed(
    'code-already-used',
    'DEMO: that code has already been used on this device.',
  ),
  attemptsExceeded(
    'attempts-exceeded',
    'DEMO: too many attempts. Ask for a new code.',
  ),
  duplicateDevice(
    'duplicate-device',
    'This device is already registered; unpair it first.',
  ),
  transportMissing(
    'transport-missing',
    'Pairing needs a transport this build does not have.',
  );

  const RegistrationRejectReason(this.wire, this.userLabel);

  final String wire;

  /// Safe to print verbatim — every entry is phrased so a fabricated DEMO
  /// outcome is never mistaken for a real one.
  final String userLabel;

  static RegistrationRejectReason? fromWire(String? raw) {
    for (final RegistrationRejectReason reason in RegistrationRejectReason.values) {
      if (reason.wire == raw) return reason;
    }
    return null;
  }
}

/// One registration state, as a value — never a nullable enum plus side fields.
///
/// [toMap] is the persisted shape and it NEVER contains a pairing code, in
/// plaintext or hashed: a 6-digit space is brute-forceable, so even a digest of
/// a DEMO code would be recoverable beside the file it came from. The only
/// code-derived fact recorded anywhere is the digit COUNT.
sealed class RegistrationStatus {
  const RegistrationStatus();

  RegistrationKind get kind;

  /// The one string a screen may print for this state.
  String get userLabel;

  Map<String, Object?> toMap();

  @override
  String toString() => kind.wire;
}
