import 'package:haven_models/haven_models.dart';

import 'registration_status.dart';

/// The event types a registration audit row may hold.
///
/// These are the events the Stage-2 contracts can actually observe on this
/// device. They are NOT the cloud `audit_logs` row shape — that table's
/// columns come from `docs/stage1/evidence/` and no Stage-2 code writes it.
enum RegistrationAuditKind {
  codeSubmitted('code-submitted'),
  codeRejected('code-rejected'),
  demoAccepted('demo-accepted'),
  duplicateBlocked('duplicate-blocked'),
  attemptsExceeded('attempts-exceeded'),
  unpairedLocally('unpaired-locally'),
  startedOver('started-over'),
  crossDeviceBlocked('cross-device-blocked'),
  stateRestoredFromMalformed('state-restored-from-malformed');

  const RegistrationAuditKind(this.wire);

  final String wire;

  static RegistrationAuditKind? fromWire(String? raw) {
    for (final RegistrationAuditKind kind in RegistrationAuditKind.values) {
      if (kind.wire == raw) return kind;
    }
    return null;
  }
}

/// One recorded registration event.
///
/// What it holds: the event type, a timestamp taken from the injected
/// `haven_core` `Clock` (so tests freeze time and no row is written with a
/// wall-clock guess), the digit COUNT of the code involved, and an optional
/// note.
///
/// What it must never hold — contract rule
/// (`docs/implementation/00-app-contract.md:108-109`, risk R-1): the pairing
/// code, in plaintext or hashed. A 6-digit code is brute-forceable in
/// milliseconds, so a digest beside the file would be a copy. There is a test
/// that scans the serialized JSON for every code a DEMO run ever handed out.
final class RegistrationAuditRow {
  const RegistrationAuditRow({
    required this.kind,
    required this.at,
    this.codeDigits,
    this.rejectReason,
    this.attemptsUsed,
    this.note,
  });

  final RegistrationAuditKind kind;
  final DateTime at;

  /// Length only, never content.
  final int? codeDigits;

  final RegistrationRejectReason? rejectReason;
  final int? attemptsUsed;

  /// Free text written by this app only — never a user-typed value, so no
  /// code can leak into it through a form.
  final String? note;

  Map<String, Object?> toMap() => <String, Object?>{
    'event': kind.wire,
    'at': at.toUtc().toIso8601String(),
    if (codeDigits != null) 'code_digits': codeDigits,
    if (rejectReason != null) 'reason': rejectReason!.wire,
    if (attemptsUsed != null) 'attempts_used': attemptsUsed,
    if (note != null) 'note': note,
  };

  /// `null` for a row this build cannot understand. Callers count it as
  /// malformed and recover honestly; they never invent a row to fill the gap.
  static RegistrationAuditRow? fromMap(Map<String, Object?> map) {
    final RegistrationAuditKind? kind = RegistrationAuditKind.fromWire(
      asText(map['event']),
    );
    final DateTime? at = asDate(map['at']);
    if (kind == null || at == null) return null;
    return RegistrationAuditRow(
      kind: kind,
      at: at,
      codeDigits: asInt(map['code_digits']),
      rejectReason: RegistrationRejectReason.fromWire(asText(map['reason'])),
      attemptsUsed: asInt(map['attempts_used']),
      note: asText(map['note']),
    );
  }

  @override
  String toString() => '${kind.wire}@${at.toIso8601String()}';
}

/// The DEMO audit lane's own limits — local bookkeeping, not a backend rule.
abstract final class RegistrationAuditLane {
  /// Rows kept on disk. Older rows are dropped oldest-first; a DEMO that
  /// silently grew an unbounded log would be a storage bug, so the cap is
  /// explicit and tested.
  static const int storedRowLimit = 60;

  static List<RegistrationAuditRow> append(
    List<RegistrationAuditRow> existing,
    RegistrationAuditRow row,
  ) {
    final List<RegistrationAuditRow> next = <RegistrationAuditRow>[
      ...existing,
      row,
    ];
    return next.length <= storedRowLimit
        ? next
        : next.sublist(next.length - storedRowLimit);
  }
}
