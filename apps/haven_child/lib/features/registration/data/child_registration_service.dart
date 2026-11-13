import 'package:haven_core/haven_core.dart';

import '../domain/registration_audit.dart';
import '../domain/registration_codec.dart';
import '../domain/registration_status.dart';

/// The child-side registration seam (Phase 3 Stage 2 = contracts only).
///
/// Two implementations exist and they are deliberately not interchangeable in
/// what they claim:
///
/// * `BlockedRegistrationService` — the honest default. Real cross-device
///   pairing is BLOCKED (decision D-5,
///   `docs/implementation/phase_3/STAGE_2_OWNER_DECISIONS.md` §3), so every
///   cross-device method returns `blocked(...)` naming the missing dependency.
/// * `DemoRegistrationService` — a local-only, deterministic simulation whose
///   every user-visible string says DEMO.
///
/// Widgets talk to this interface and to `RegistrationController`; they never
/// touch a transport, an SDK or a channel.
abstract interface class ChildRegistrationService {
  /// The status stream. It is a broadcast stream and it never errors: a failed
  /// attempt is expressed as a state plus a `Result`, not as a thrown
  /// exception.
  Stream<RegistrationStatus> get state;

  /// The current value, readable synchronously so a label widget can render
  /// before the first event arrives.
  RegistrationStatus get current;

  /// What kind of lane this is, in one word a screen can print: `DEMO` or
  /// `BLOCKED`. Never `real`.
  String get laneLabel;

  /// Offers a typed pairing code.
  ///
  /// `Ok` carries the resulting state. Failures are typed: a
  /// [ValidationFailure] for an illegal transition or a bad code, a
  /// [BlockedFailure] when the lane itself does not exist, and a
  /// [StorageFailure] when the local document refused the write — in which
  /// case the in-memory state is rolled back, because a change the disk did
  /// not accept is not reported as a success.
  Future<Result<RegistrationStatus>> submitPairingCode(String code);

  /// Removes this device's registration.
  ///
  /// In the DEMO lane that is a local unpair. Telling a parent or a server is
  /// BLOCKED, so no implementation may claim the parent was notified.
  Future<Result<RegistrationStatus>> unpair();

  /// Re-reads whatever this lane persisted. The DEMO lane restores status,
  /// stable id and audit rows; the BLOCKED lane has nothing stored and
  /// answers with the empty snapshot (an `Ok`, not a failure — there genuinely
  /// is no registration to lose).
  Future<Result<RegistrationSnapshot>> restore();

  /// The rows this service has recorded, newest last. Never contains a code.
  List<RegistrationAuditRow> get audit;
}
