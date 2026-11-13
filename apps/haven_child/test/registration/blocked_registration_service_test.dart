import 'package:flutter_test/flutter_test.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_child/features/registration/data/blocked_registration_service.dart';
import 'package:haven_child/features/registration/domain/registration_audit.dart';
import 'package:haven_child/features/registration/domain/registration_codec.dart';
import 'package:haven_child/features/registration/domain/registration_status.dart';

/// The lane the child app registers by default, and the reason D-5 stays
/// BLOCKED in code rather than in a document only: every cross-device method
/// answers `blocked(...)` naming the missing dependency, so no screen can
/// render a pairing that did not happen.
void main() {
  test('the lane announces itself as BLOCKED and starts unregistered', () {
    final BlockedRegistrationService service = BlockedRegistrationService();
    expect(service.laneLabel, 'BLOCKED');
    expect(service.current, isA<Unregistered>());
    expect(service.audit, isEmpty);
  });

  test('submitting a pairing code is blocked, with the missing piece named', () async {
    final BlockedRegistrationService service = BlockedRegistrationService();
    final Result<RegistrationStatus> result =
        await service.submitPairingCode('123456');
    final HavenFailure failure = result.failureOrNull!;

    expect(result.isErr, isTrue);
    expect(isBlocked(result), isTrue, reason: 'the shared honest vocabulary');
    expect(failure, isA<BlockedFailure>());
    expect(
      (failure as BlockedFailure).missing,
      BlockedRegistrationService.missingTransport,
    );
    expect(failure.missing, contains('approved cross-device pairing transport'));
    expect(failure.missing, contains('D-5'));
    expect(failure.detail, startsWith('BLOCKED — SPECIFICATION REQUIRED:'));
    expect(failure.message, BlockedRegistrationService.blockedRequirement);
    expect(failure.message, contains('Haven cannot link this child device'));
  });

  test('unpair is blocked for a different missing dependency', () async {
    final BlockedRegistrationService service = BlockedRegistrationService();
    final Result<RegistrationStatus> result = await service.unpair();
    final BlockedFailure failure = result.failureOrNull! as BlockedFailure;

    expect(failure.missing, BlockedRegistrationService.missingRevocationLane);
    expect(failure.missing, contains('revoke_device'));
    expect(
      failure.message,
      contains('Haven cannot confirm an unpair'),
      reason: 'a refusal to notify a parent, not a refusal to clear local state',
    );
    expect(
      BlockedRegistrationService.missingDependencies,
      <String>[
        BlockedRegistrationService.missingTransport,
        BlockedRegistrationService.missingRevocationLane,
      ],
    );
  });

  test('no plaintext code survives a blocked attempt, even in the audit lane', () async {
    final BlockedRegistrationService service = BlockedRegistrationService(
      recordAudit: true,
      clock: FixedClock(DateTime.utc(2026, 11, 13)),
    );
    await service.submitPairingCode('246810');
    await service.unpair();

    expect(
      service.audit.map((RegistrationAuditRow r) => r.kind).toList(),
      const <RegistrationAuditKind>[
        RegistrationAuditKind.crossDeviceBlocked,
        RegistrationAuditKind.crossDeviceBlocked,
      ],
    );
    for (final RegistrationAuditRow row in service.audit) {
      expect(row.codeDigits, isNull);
      expect(
        row.toMap().values.whereType<String>().any((String v) => v.contains('246810')),
        isFalse,
        reason: 'a refusal note must never carry the typed code back out',
      );
    }
  });

  test('restore has nothing to lose and says so without failing', () async {
    final BlockedRegistrationService service = BlockedRegistrationService();
    final Result<RegistrationSnapshot> loaded = await service.restore();
    expect(loaded.isOk, isTrue);
    expect(loaded.valueOrNull!.status, isA<Unregistered>());
    expect(loaded.valueOrNull!.stableLocalId, isNull);
    expect(loaded.valueOrNull!.audit, isEmpty);
  });

  test('the stream reports the honest current state and never an invented one', () async {
    final BlockedRegistrationService service = BlockedRegistrationService();
    final List<RegistrationKind> seen = <RegistrationKind>[];
    await for (final RegistrationStatus status in service.state) {
      seen.add(status.kind);
    }
    expect(seen, const <RegistrationKind>[RegistrationKind.unregistered]);
  });

  test('a blocked lane cannot be talked into a registration by a screen', () async {
    final BlockedRegistrationService service = BlockedRegistrationService();
    await service.submitPairingCode('000000');
    await service.unpair();
    expect(service.current, isA<Unregistered>());
    expect(service.current.userLabel, isNot(contains('Registered')));
  });
}
