part of 'registration_status.dart';

/// Unregistered: nothing has ever been registered on this device.
final class Unregistered extends RegistrationStatus {
  const Unregistered();

  static const String label =
      'Not registered — this device is not linked to a parent.';

  @override
  RegistrationKind get kind => RegistrationKind.unregistered;

  @override
  String get userLabel => label;

  @override
  Map<String, Object?> toMap() => <String, Object?>{'kind': kind.wire};
}

/// A DEMO code has been offered or typed and is inside its simulated TTL.
///
/// [expiresAt] carries the D-3 option (ii) DEMO shape only: 6 digits, 5 minutes
/// — the parent simulation's shape, NOT the Phase-4 backend target
/// (`STAGE_2_OWNER_DECISIONS.md` §1).
final class DemoPending extends RegistrationStatus {
  const DemoPending({
    required this.startedAt,
    required this.expiresAt,
    this.attemptsUsed = 0,
    this.codeDigits = 6,
  });

  final DateTime startedAt;
  final DateTime expiresAt;
  final int attemptsUsed;

  /// How long the typed code was, recorded instead of the code itself.
  final int codeDigits;

  bool isExpiredAt(DateTime at) => !at.isBefore(expiresAt);

  Duration remainingAt(DateTime at) =>
      isExpiredAt(at) ? Duration.zero : expiresAt.difference(at);

  @override
  RegistrationKind get kind => RegistrationKind.demoPending;

  @override
  String get userLabel => 'DEMO — waiting on this device only. No parent phone '
      'has been contacted.';

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    'kind': kind.wire,
    'started_at': startedAt.toUtc().toIso8601String(),
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'attempts_used': attemptsUsed,
    'code_digits': codeDigits,
  };
}

/// Registered. In this build the only way to reach it is the DEMO lane, so the
/// label says so out loud.
final class Registered extends RegistrationStatus {
  const Registered({required this.stableLocalId, required this.registeredAt});

  final String stableLocalId;
  final DateTime registeredAt;

  @override
  RegistrationKind get kind => RegistrationKind.registered;

  @override
  String get userLabel => 'Registered (DEMO — simulated locally; the phone '
      'never met another device).';

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    'kind': kind.wire,
    'stable_local_id': stableLocalId,
    'registered_at': registeredAt.toUtc().toIso8601String(),
  };
}

/// A refused attempt. [reason] is one of the typed reasons above and
/// [attemptsUsed] is the running DEMO counter.
final class Rejected extends RegistrationStatus {
  const Rejected({
    required this.reason,
    required this.attemptsUsed,
    required this.at,
  });

  final RegistrationRejectReason reason;
  final int attemptsUsed;
  final DateTime at;

  @override
  RegistrationKind get kind => RegistrationKind.rejected;

  @override
  String get userLabel => 'Not registered — ${reason.userLabel}';

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    'kind': kind.wire,
    'reason': reason.wire,
    'attempts_used': attemptsUsed,
    'rejected_at': at.toUtc().toIso8601String(),
  };
}

/// A registration that was removed on THIS device (the DEMO's local unpair).
/// A real revocation would come from the parent or the backend — both BLOCKED.
final class Revoked extends RegistrationStatus {
  const Revoked({required this.at, this.stableLocalId, this.note});

  final DateTime at;

  /// Kept so a relaunch cannot mint a second identity for the same device
  /// (duplicate-registration protection).
  final String? stableLocalId;
  final String? note;

  @override
  RegistrationKind get kind => RegistrationKind.revoked;

  @override
  String get userLabel => 'Unpaired on this device (DEMO — nothing was told to '
      'a parent phone or a server).';

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    'kind': kind.wire,
    'revoked_at': at.toUtc().toIso8601String(),
    if (stableLocalId != null) 'stable_local_id': stableLocalId,
    if (note != null) 'note': note,
  };
}
