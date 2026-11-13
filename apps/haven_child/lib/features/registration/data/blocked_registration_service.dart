import 'package:haven_core/haven_core.dart';

import '../domain/registration_audit.dart';
import '../domain/registration_codec.dart';
import '../domain/registration_status.dart';
import 'child_registration_service.dart';

/// The honest lane: NO cross-device registration exists in this build.
///
/// Decision D-5 (`STAGE_2_OWNER_DECISIONS.md` §3) keeps real parent↔child
/// exchange BLOCKED — there is no approved transport, no QR/BLE/file exchange,
/// and no deployed backend pairing function. A blocked prerequisite is not
/// treated as satisfied by simulation (§7 item 2), so this class answers every
/// cross-device method with `blocked(...)` and names the missing piece exactly.
///
/// It is the seam the child app registers by default. A screen wired to this
/// class can only ever render a refusal, which is the point: nothing here can
/// make a parent believe two phones met.
final class BlockedRegistrationService implements ChildRegistrationService {
  /// Not `const`: the audit list is a field initialiser, and an
  /// `UnmodifiableList` view of it is what [audit] hands out.
  BlockedRegistrationService({
    this.clock = systemClock,
    this.recordAudit = false,
  });

  static const String demoLaneNote =
      'Only the labelled local DEMO lane can change registration state in this '
      'build.';

  /// What is missing for `submitPairingCode` to ever return anything else.
  static const String missingTransport =
      'an approved cross-device pairing transport and a deployed pairing '
      'backend (decision D-5: BLOCKED — no transport authorized for Phase 3 '
      'Stage 2; backend pairing is Phase 4 and staging has 0 deployed '
      'functions)';

  /// What is missing for `unpair` to be able to tell the parent.
  static const String missingRevocationLane =
      'the `revoke_device` RPC / `device-register` Edge Function call path (not '
      'reachable from this build: no backend configured and no approved '
      'transport — decision D-5)';

  static const String blockedRequirement =
      'Haven cannot link this child device to a parent in this build, and it '
      "won't pretend otherwise.";

  final Clock clock;

  /// Off by default: a refusal needs no paper trail until a UI asks for one.
  final bool recordAudit;

  final List<RegistrationAuditRow> _audit = <RegistrationAuditRow>[];

  @override
  RegistrationStatus get current => const Unregistered();

  @override
  String get laneLabel => 'BLOCKED';

  @override
  Stream<RegistrationStatus> get state =>
      Stream<RegistrationStatus>.value(current);

  @override
  Future<Result<RegistrationStatus>> submitPairingCode(String code) async {
    _record(RegistrationAuditKind.crossDeviceBlocked, note: missingTransport);
    return blocked<RegistrationStatus>(
      missingTransport,
      requirement: blockedRequirement,
    );
  }

  @override
  Future<Result<RegistrationStatus>> unpair() async {
    _record(RegistrationAuditKind.crossDeviceBlocked, note: missingRevocationLane);
    return blocked<RegistrationStatus>(
      missingRevocationLane,
      requirement:
          'Haven cannot confirm an unpair with a parent in this build. The '
          'local DEMO lane can clear its own local state, and it says DEMO '
          'when it does.',
    );
  }

  @override
  List<RegistrationAuditRow> get audit =>
      List<RegistrationAuditRow>.unmodifiable(_audit);

  /// Nothing is stored on this lane, so there is nothing to restore: the
  /// honest answer is the empty snapshot, not a failure and not a `blocked`.
  @override
  Future<Result<RegistrationSnapshot>> restore() async =>
      Ok<RegistrationSnapshot>(RegistrationSnapshot(status: current));

  /// The two reasons this lane refuses, kept in one place so a test and a
  /// BlockedNotice read the same strings the UI shows.
  static List<String> get missingDependencies =>
      const <String>[missingTransport, missingRevocationLane];

  void _record(RegistrationAuditKind kind, {required String note}) {
    if (!recordAudit) return;
    _audit.add(
      RegistrationAuditRow(kind: kind, at: clock.now(), note: note),
    );
  }
}
