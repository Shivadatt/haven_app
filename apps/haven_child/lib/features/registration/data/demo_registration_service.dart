import 'dart:async';

import 'package:haven_api/haven_api.dart' show LocalIds;
import 'package:haven_core/haven_core.dart';

import '../domain/registration_audit.dart';
import '../domain/registration_codec.dart';
import '../domain/registration_status.dart';
import '../domain/registration_transitions.dart';
import 'child_registration_service.dart';
import 'demo_code_lane.dart';
import 'demo_registration_journal.dart';
import 'demo_registration_policy.dart';
import 'registration_repository.dart';

/// The labelled DEMO lane: local-only, deterministic, in-memory; real pairing
/// is D-5 BLOCKED (this is the child side of the Stage-2 CONTRACT). Code and
/// journal bookkeeping live in [DemoCodeLane] and [DemoRegistrationJournal]
/// (200-line source rule); this orchestrator keeps the original public API
/// and the test-frozen validation order. Plaintext codes live only in memory.
final class DemoRegistrationService implements ChildRegistrationService {
  DemoRegistrationService({
    this.clock = systemClock,
    this.policy = const DemoRegistrationPolicy(),
    this.persistence,
    String Function()? localIdMinter,
  })  : _localIdMinter = localIdMinter ?? _defaultLocalId,
        _codes = DemoCodeLane(clock: clock, policy: policy),
        _journal = DemoRegistrationJournal(persistence: persistence, clock: clock);

  static String _defaultLocalId() => 'child-${LocalIds.create(bytes: 8)}';

  final Clock clock;
  final DemoRegistrationPolicy policy;

  final RegistrationRepository? persistence;
  final String Function() _localIdMinter;
  final DemoCodeLane _codes;
  final DemoRegistrationJournal _journal;
  final StreamController<RegistrationStatus> _events =
      StreamController<RegistrationStatus>.broadcast();

  @override
  RegistrationStatus get current => _journal.snapshot.status;
  @override
  String get laneLabel => 'DEMO';
  @override
  Stream<RegistrationStatus> get state => _events.stream;
  @override
  List<RegistrationAuditRow> get audit =>
      List<RegistrationAuditRow>.unmodifiable(_journal.snapshot.audit);
  RegistrationSnapshot get snapshot => _journal.snapshot;
  int get attemptsUsed => _codes.attemptsUsed;

  // Restored failures are typed and leave in-memory state untouched.
  @override
  Future<Result<RegistrationSnapshot>> restore() async {
    final RegistrationRepository? repo = persistence;
    if (repo == null) return Ok<RegistrationSnapshot>(_journal.snapshot);
    final loaded = await repo.load();
    final RegistrationSnapshot? stored = loaded.valueOrNull;
    if (stored == null) return Err<RegistrationSnapshot>(loaded.failureOrNull!);
    _journal.snapshot = stored;
    final RegistrationStatus restored = stored.status;
    if (restored is DemoPending) _codes.restoreAttempts(restored.attemptsUsed);
    _events.add(stored.status);
    return loaded;
  }

  String issueDemoCode() => _codes.issue();

  @override
  Future<Result<RegistrationStatus>> submitPairingCode(String code) async {
    final String typed = _codes.normalize(code);
    final RegistrationStatus prior = _journal.snapshot.status;

    // 1. Duplicate: `registered -> demoPending` is not in the table.
    if (prior is Registered) {
      await _journal.recordOnly(RegistrationAuditKind.duplicateBlocked,
          attempts: _codes.attemptsUsed,
          codeDigits: typed.length,
          note: 'already_registered');
      return Err<RegistrationStatus>(RegistrationTransitions.illegalTransition(
          prior,
          DemoPending(
              startedAt: clock.now(),
              expiresAt: clock.now().add(policy.codeTtl))));
    }

    // 2. Attempt cap (N is the Phase-4 target; see DemoRegistrationPolicy).
    if (_codes.countAttempt()) {
      return _reject(RegistrationRejectReason.attemptsExceeded, typed,
          RegistrationAuditKind.attemptsExceeded);
    }

    // 3-5. Frozen order: shape, 5-min DEMO expiry, never-issued, reuse,
    //      mismatch (D-3 option (ii); frozen by service tests).
    final DemoCodeRejection? rejection = _codes.rejectionFor(typed);
    if (rejection != null) {
      return _reject(
        switch (rejection) {
          DemoCodeRejection.badShape => RegistrationRejectReason.codeFormat,
          DemoCodeRejection.expired => RegistrationRejectReason.codeExpired,
          DemoCodeRejection.neverIssued ||
          DemoCodeRejection.mismatch =>
            RegistrationRejectReason.codeMismatch,
          DemoCodeRejection.alreadyRedeemed =>
            RegistrationRejectReason.codeAlreadyUsed,
        },
        typed,
        RegistrationAuditKind.codeRejected,
        note: rejection == DemoCodeRejection.neverIssued
            ? 'no_demo_code_issued_on_this_device'
            : null,
      );
    }

    // 6. Accept: pending (within the TTL window), then registered.
    final DateTime now = clock.now();
    final accepted = await _commit(
      DemoPending(
          startedAt: now,
          expiresAt: now.add(policy.codeTtl),
          attemptsUsed: _codes.attemptsUsed,
          codeDigits: typed.length),
      RegistrationAuditKind.codeSubmitted,
      codeDigits: typed.length,
    );
    if (accepted.isErr) return accepted;
    final committed = await _commit(
      Registered(stableLocalId: _stableId(), registeredAt: clock.now()),
      RegistrationAuditKind.demoAccepted,
      codeDigits: typed.length,
    );
    if (committed.isOk) _codes.accept(typed);
    return committed;
  }

  @override
  Future<Result<RegistrationStatus>> unpair() => _commit(
        Revoked(
            at: clock.now(),
            stableLocalId: _journal.snapshot.stableLocalId,
            note: 'DEMO local unpair'),
        RegistrationAuditKind.unpairedLocally,
        note: DemoRegistrationPolicy.demoLandingNote,
      );

  // Stable id and audit rows survive a start-over: duplicate protection.
  Future<Result<RegistrationStatus>> startOver() => _commit(
        const Unregistered(),
        RegistrationAuditKind.startedOver,
        note: 'local DEMO reset',
      );

  void dispose() {
    _events.close();
    _codes.dispose();
  }

  Future<Result<RegistrationStatus>> _reject(
    RegistrationRejectReason reason,
    String typed,
    RegistrationAuditKind kind, {
    String? note,
  }) =>
      _commit(
          Rejected(reason: reason, attemptsUsed: _codes.attemptsUsed,
              at: clock.now()),
          kind,
          codeDigits: typed.length, rejectReason: reason, note: note);

  Future<Result<RegistrationStatus>> _commit(
    RegistrationStatus next,
    RegistrationAuditKind kind, {
    int? codeDigits,
    RegistrationRejectReason? rejectReason,
    String? note,
  }) async {
    final Result<RegistrationStatus> result = await _journal.commit(
      next,
      kind,
      attempts: _codes.attemptsUsed,
      codeDigits: codeDigits,
      rejectReason: rejectReason,
      note: note,
    );
    // A change the local document refused rolls back and is never emitted.
    if (result.isOk) _events.add(next);
    return result;
  }

  String _stableId() {
    final RegistrationStatus stored = _journal.snapshot.status;
    final String? existing = _journal.snapshot.stableLocalId ??
        (stored is Registered ? stored.stableLocalId : null);
    if (existing != null && existing.isNotEmpty) return existing;
    return _localIdMinter();
  }
}
