import 'package:haven_models/haven_models.dart';

import 'registration_audit.dart';
import 'registration_status.dart';

/// Everything the child's storage lane is allowed to remember about
/// registration: the status, the device's stable local id, and the audit rows.
///
/// That list is exhaustive on purpose. No pairing code, no token, no parent
/// identity, no device name — see the audit row's note about contract rule R-1.
final class RegistrationSnapshot {
  const RegistrationSnapshot({
    required this.status,
    this.stableLocalId,
    this.audit = const <RegistrationAuditRow>[],
  });

  factory RegistrationSnapshot.empty() => const RegistrationSnapshot(
    status: Unregistered(),
  );

  final RegistrationStatus status;

  /// Minted once per device and kept across an unpair, so a second
  /// registration on the same phone cannot look like a new device.
  final String? stableLocalId;

  final List<RegistrationAuditRow> audit;

  RegistrationSnapshot copyWith({
    RegistrationStatus? status,
    String? stableLocalId,
    List<RegistrationAuditRow>? audit,
  }) => RegistrationSnapshot(
    status: status ?? this.status,
    stableLocalId: stableLocalId ?? this.stableLocalId,
    audit: audit ?? this.audit,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'status': status.toMap(),
    if (stableLocalId != null) 'stable_local_id': stableLocalId,
    'audit': <Object?>[for (final row in audit) row.toMap()],
  };
}

/// The persisted map <-> typed-value rules for the `registration` section.
///
/// Malformed data is NEVER guessed at: [decodeSnapshot] answers `null` and the
/// repository recovers to `Unregistered` with an audit row that says it did.
abstract final class RegistrationCodec {
  static const String statusKey = 'status';
  static const String stableIdKey = 'stable_local_id';
  static const String auditKey = 'audit';
  static const String kindKey = 'kind';

  static RegistrationSnapshot? decodeSnapshot(Map<String, Object?> map) {
    final Object? rawStatus = map[statusKey];
    if (rawStatus is! Map) return null;
    final RegistrationStatus? status = decodeStatus(
      rawStatus.cast<String, Object?>(),
    );
    if (status == null) return null;
    final List<RegistrationAuditRow> rows = <RegistrationAuditRow>[];
    final Object? rawAudit = map[auditKey];
    if (rawAudit != null && rawAudit is! List) return null;
    for (final Object? entry in asList(rawAudit)) {
      if (entry is! Map) return null;
      final RegistrationAuditRow? row = RegistrationAuditRow.fromMap(
        entry.cast<String, Object?>(),
      );
      if (row == null) return null;
      rows.add(row);
    }
    return RegistrationSnapshot(
      status: status,
      stableLocalId: asText(map[stableIdKey]),
      audit: rows,
    );
  }

  /// `null` for an unknown or incomplete `kind`, including a `kind` written by
  /// a future build that this one cannot honour.
  static RegistrationStatus? decodeStatus(Map<String, Object?> map) {
    final RegistrationKind? kind = RegistrationKind.fromWire(
      asText(map[RegistrationCodec.kindKey]),
    );
    if (kind == null) return null;
    return switch (kind) {
      RegistrationKind.unregistered => const Unregistered(),
      RegistrationKind.demoPending => _demoPending(map),
      RegistrationKind.registered => _registered(map),
      RegistrationKind.rejected => _rejected(map),
      RegistrationKind.revoked => _revoked(map),
    };
  }

  static RegistrationStatus? _demoPending(Map<String, Object?> map) {
    final DateTime? started = asDate(map['started_at']);
    final DateTime? expires = asDate(map['expires_at']);
    if (started == null || expires == null) return null;
    return DemoPending(
      startedAt: started,
      expiresAt: expires,
      attemptsUsed: asInt(map['attempts_used']) ?? 0,
      codeDigits: asInt(map['code_digits']) ?? 0,
    );
  }

  static RegistrationStatus? _registered(Map<String, Object?> map) {
    final String? id = asText(map['stable_local_id']);
    final DateTime? at = asDate(map['registered_at']);
    if (id == null || id.isEmpty || at == null) return null;
    return Registered(stableLocalId: id, registeredAt: at);
  }

  static RegistrationStatus? _rejected(Map<String, Object?> map) {
    final RegistrationRejectReason? reason = RegistrationRejectReason.fromWire(
      asText(map['reason']),
    );
    final DateTime? at = asDate(map['rejected_at']);
    if (reason == null || at == null) return null;
    return Rejected(
      reason: reason,
      attemptsUsed: asInt(map['attempts_used']) ?? 0,
      at: at,
    );
  }

  static RegistrationStatus? _revoked(Map<String, Object?> map) {
    final DateTime? at = asDate(map['revoked_at']);
    if (at == null) return null;
    return Revoked(
      at: at,
      stableLocalId: asText(map[stableIdKey]),
      note: asText(map['note']),
    );
  }
}
