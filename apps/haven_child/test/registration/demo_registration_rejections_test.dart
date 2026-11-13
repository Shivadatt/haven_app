import 'package:flutter_test/flutter_test.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_child/features/registration/data/demo_registration_policy.dart';
import 'package:haven_child/features/registration/domain/registration_audit.dart';
import 'package:haven_child/features/registration/domain/registration_status.dart';

import 'registration_test_support.dart';

/// The refusal half of the labelled DEMO lane, split out of
/// `demo_registration_service_test.dart` under the 200-line source rule —
/// behaviour and assertions unchanged. These are the tests that FREEZE the
/// validation shape and reuse guard (code format, typing hygiene, the attempt
/// cap and duplicate/reuse protection); moving a check here is a contract
/// change, not a refactor. Expiry and the never-minted refusal stay in the
/// service file alongside the accepted-registration lifecycle.
void main() {
  test('the DEMO shape is the DEMO shape: 6 digits, nothing else', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    lane.demo.issueDemoCode();
    for (final String wrong in <String>['12345', '1234567', 'abcdef', '12 34-']) {
      final RegistrationStatus status =
          (await lane.demo.submitPairingCode(wrong)).valueOrNull!;
      expect(
        status,
        isA<Rejected>(),
        reason: '"$wrong" is not 6 digits',
      );
      expect(
        (status as Rejected).reason,
        RegistrationRejectReason.codeFormat,
      );
    }
    expect(lane.demo.attemptsUsed, 4);
  });

  test('spaces and dashes are typing hygiene, not a second code shape', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    final String code = lane.demo.issueDemoCode();
    final String spaced = '${code.substring(0, 3)} ${code.substring(3)}';
    expect(
      (await lane.demo.submitPairingCode(spaced)).valueOrNull,
      isA<Registered>(),
    );
  });

  test('attempts are counted, and the cap rejects further tries', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness(
      policy: const DemoRegistrationPolicy(maxAttempts: 2),
    );
    lane.demo.issueDemoCode();

    await lane.demo.submitPairingCode('999999');
    expect(lane.demo.attemptsUsed, 1);
    await lane.demo.submitPairingCode('999998');
    expect(lane.demo.attemptsUsed, 2);

    final RegistrationStatus third =
        (await lane.demo.submitPairingCode('999997')).valueOrNull!;
    expect(
      (third as Rejected).reason,
      RegistrationRejectReason.attemptsExceeded,
    );
    expect(third.attemptsUsed, 3);
    expect(
      lane.demo.audit.last.kind,
      RegistrationAuditKind.attemptsExceeded,
    );
    expect(
      third.userLabel,
      contains('too many attempts'),
      reason: 'the copy says the DEMO refused, not a parent',
    );
  });

  test('duplicate protection: a registered device cannot register twice', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    final String code = lane.demo.issueDemoCode();
    await lane.demo.submitPairingCode(code);

    final String second = lane.demo.issueDemoCode();
    final Result<RegistrationStatus> again =
        await lane.demo.submitPairingCode(second);
    final HavenFailure failure = again.failureOrNull!;
    expect(again.isErr, isTrue);
    expect(failure, isA<ValidationFailure>());
    expect(
      (failure as ValidationFailure).detail,
      contains('illegal_transition: registered -> demoPending'),
      reason: 'the transitions table is the guard, not a bespoke if-statement',
    );
    expect(lane.demo.current, isA<Registered>());
    expect(lane.demo.audit.last.kind, RegistrationAuditKind.duplicateBlocked);

    // The same code cannot be redeemed twice even after it was used.
    await lane.demo.unpair();
    await lane.demo.startOver();
    final RegistrationStatus reused =
        (await lane.demo.submitPairingCode(code)).valueOrNull!;
    expect(
      (reused as Rejected).reason,
      isNot(RegistrationRejectReason.codeMismatch),
      reason: 'the refusal is about reuse, not about not recognising it',
    );
  });
}
