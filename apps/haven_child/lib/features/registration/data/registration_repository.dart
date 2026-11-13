import 'package:haven_core/haven_core.dart';

import '../../../../core/storage/child_local_state.dart';
import '../domain/registration_audit.dart';
import '../domain/registration_codec.dart';
import '../domain/registration_status.dart';

/// The persistence seam for registration state.
abstract interface class RegistrationRepository {
  /// The stored snapshot. A missing section is `Unregistered`; a damaged
  /// section recovers to `Unregistered` with a recorded reason; a damaged
  /// DOCUMENT is a typed failure and is never reset here.
  Future<Result<RegistrationSnapshot>> load();

  /// Writes the whole snapshot in one section replace. A failure means the
  /// change did not happen — callers must roll their in-memory state back.
  Future<Result<void>> save(RegistrationSnapshot snapshot);

  /// Removes the section (the child's data-reset path calls it).
  Future<Result<void>> clear();
}

/// Persists through the child app's ONE existing storage lane.
///
/// Storage decision (Stage 2 brief, workstream A item 3): no competing
/// database, no new file. `ChildLocalStateStore` already owns the additive
/// `childLocalState` key inside `haven_local.json` and already handles the
/// two-writers-one-document discipline (re-read before write, then
/// `LocalTables.reload()`). Registration therefore lands as one more section
/// next to `session` and `onboarding` — same document, same writer.
///
/// What is persisted is exactly the [RegistrationSnapshot] fields: status,
/// stable local id, audit rows. Nothing else — no pairing code, in any form.
final class LocalRegistrationRepository implements RegistrationRepository {
  LocalRegistrationRepository(
    this._state, {
    this.clock = systemClock,
    this.repairMalformedSection = true,
  });

  /// The additive section key, sibling of
  /// `ChildLocalStateStore.sessionSection` / `onboardingSection`.
  static const String registrationSection = 'registration';

  final ChildLocalStateStore _state;
  final Clock clock;

  /// When true, a section this build cannot read is replaced with the honest
  /// `Unregistered` snapshot plus an audit row, so the device is not stuck
  /// reading garbage on every launch. The FILE is never touched: a corrupt
  /// document still fails typed, exactly as `malformed_recovery_test.dart`
  /// requires of the engine underneath.
  final bool repairMalformedSection;

  @override
  Future<Result<RegistrationSnapshot>> load() async {
    final read = await _state.readSection(registrationSection);
    if (read.isErr) return Err<RegistrationSnapshot>(read.failureOrNull!);
    final Map<String, Object?>? map = read.valueOrNull;
    if (map == null) return Ok<RegistrationSnapshot>(RegistrationSnapshot.empty());

    final RegistrationSnapshot? decoded = RegistrationCodec.decodeSnapshot(map);
    if (decoded != null) {
      return Ok<RegistrationSnapshot>(
        _withPendingExpiryApplied(decoded),
      );
    }
    final RegistrationSnapshot repaired = RegistrationSnapshot(
      status: const Unregistered(),
      audit: <RegistrationAuditRow>[
        RegistrationAuditRow(
          kind: RegistrationAuditKind.stateRestoredFromMalformed,
          at: clock.now(),
          note: 'registration_section_unreadable',
        ),
      ],
    );
    if (repairMalformedSection) {
      final saved = await save(repaired);
      if (saved.isErr) return Err<RegistrationSnapshot>(saved.failureOrNull!);
    }
    return Ok<RegistrationSnapshot>(repaired);
  }

  @override
  Future<Result<void>> save(RegistrationSnapshot snapshot) =>
      _state.writeSection(registrationSection, snapshot.toMap());

  @override
  Future<Result<void>> clear() =>
      _state.writeSection(registrationSection, null);

  /// A pending DEMO attempt that outlived its simulated TTL is not "pending"
  /// any more: the restart reports it as expired instead of offering it again.
  /// `demoPending -> rejected` is a legal transition, so this normalisation
  /// agrees with [RegistrationTransitions].
  RegistrationSnapshot _withPendingExpiryApplied(RegistrationSnapshot stored) {
    final RegistrationStatus status = stored.status;
    if (status is DemoPending && clock.isPast(status.expiresAt)) {
      return stored.copyWith(
        status: Rejected(
          reason: RegistrationRejectReason.codeExpired,
          attemptsUsed: status.attemptsUsed,
          at: clock.now(),
        ),
      );
    }
    return stored;
  }
}
