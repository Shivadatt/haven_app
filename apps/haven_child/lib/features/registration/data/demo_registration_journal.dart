import 'package:haven_core/haven_core.dart';

import '../domain/registration_audit.dart';
import '../domain/registration_codec.dart';
import '../domain/registration_status.dart';
import '../domain/registration_transitions.dart';
import 'registration_repository.dart';

/// The DEMO lane's state-change bookkeeping: transition first, audit row
/// beside it, persist before the in-memory snapshot moves.
///
/// Split out of `demo_registration_service.dart` under the 200-line source
/// rule; every rule it carries is the service's original one:
/// * an illegal move is the typed failure [RegistrationTransitions] gives,
///   returned instead of stored;
/// * a write the local document refused rolls the change back — the snapshot
///   does not move and no event is emitted, because a change the disk did not
///   accept is not reported as a success;
/// * audit rows hold the digit COUNT only, never a code.
final class DemoRegistrationJournal {
  DemoRegistrationJournal({this.persistence, required this.clock});

  final RegistrationRepository? persistence;
  final Clock clock;

  RegistrationSnapshot snapshot = RegistrationSnapshot.empty();

  /// Moves the snapshot to [next] with one appended audit row.
  Future<Result<RegistrationStatus>> commit(
    RegistrationStatus next,
    RegistrationAuditKind kind, {
    required int attempts,
    int? codeDigits,
    RegistrationRejectReason? rejectReason,
    String? note,
    String? Function()? stableLocalIdFor,
  }) async {
    final RegistrationSnapshot prior = snapshot;
    final Result<RegistrationStatus> moved = RegistrationTransitions.move(
      prior.status,
      next,
    );
    if (moved.isErr) return moved;

    final RegistrationSnapshot candidate = prior.copyWith(
      status: next,
      stableLocalId: next is Registered
          ? next.stableLocalId
          : (stableLocalIdFor?.call() ?? prior.stableLocalId),
      audit: _row(
        prior.audit,
        kind,
        attempts: attempts,
        codeDigits: codeDigits,
        rejectReason: rejectReason,
        note: note,
      ),
    );
    return _store(candidate, moved);
  }

  /// An audit row that does not move state (the duplicate refusal). Still
  /// written through the repository, still containing no code.
  Future<Result<RegistrationStatus>> recordOnly(
    RegistrationAuditKind kind, {
    required int attempts,
    int? codeDigits,
    String? note,
  }) async {
    final RegistrationSnapshot candidate = snapshot.copyWith(
      audit: _row(
        snapshot.audit,
        kind,
        attempts: attempts,
        codeDigits: codeDigits,
        note: note,
      ),
    );
    final repo = persistence;
    if (repo == null) {
      snapshot = candidate;
      return Ok<RegistrationStatus>(candidate.status);
    }
    final saved = await repo.save(candidate);
    if (saved.isOk) snapshot = candidate;
    return saved.isOk
        ? Ok<RegistrationStatus>(candidate.status)
        : Err<RegistrationStatus>(saved.failureOrNull!);
  }

  Future<Result<RegistrationStatus>> _store(
    RegistrationSnapshot candidate,
    Result<RegistrationStatus> moved,
  ) async {
    final repo = persistence;
    if (repo != null) {
      final saved = await repo.save(candidate);
      if (saved.isErr) return Err<RegistrationStatus>(saved.failureOrNull!);
    }
    snapshot = candidate;
    return moved;
  }

  List<RegistrationAuditRow> _row(
    List<RegistrationAuditRow> existing,
    RegistrationAuditKind kind, {
    required int attempts,
    int? codeDigits,
    RegistrationRejectReason? rejectReason,
    String? note,
  }) => RegistrationAuditLane.append(
    existing,
    RegistrationAuditRow(
      kind: kind,
      at: clock.now(),
      codeDigits: codeDigits,
      rejectReason: rejectReason,
      attemptsUsed: attempts,
      note: note,
    ),
  );
}
