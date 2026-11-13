import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_child/features/registration/data/demo_registration_policy.dart';
import 'package:haven_child/features/registration/data/demo_registration_service.dart';
import 'package:haven_child/features/registration/domain/registration_audit.dart';
import 'package:haven_child/features/registration/domain/registration_status.dart';

import 'registration_test_support.dart';

/// The labelled DEMO lane's acceptance + lifecycle behaviour, tested at ladder
/// level 2 (pure Flutter logic). The refusal / validation-order cases (shape,
/// typing hygiene, attempt cap, duplicate/reuse) live in
/// `demo_registration_rejections_test.dart`; both files drive the same
/// `RegistrationTestHarness`. Nothing here claims a device was paired: the
/// assertions are about the contract — honesty before any action, the accepted
/// registration, stream ordering, injected-clock expiry, the never-minted
/// refusal, unpair, startOver and the shape of the audit rows. Every clock read
/// is a `FixedClock`, so no test sleeps and no test depends on the wall clock.
void main() {
  test('the DEMO lane is honest about what it is before anything happens', () {
    final DemoRegistrationService service = RegistrationTestHarness().demo;
    expect(service.laneLabel, 'DEMO');
    expect(service.current, isA<Unregistered>());
    expect(service.current.userLabel, contains('Not registered'));
    expect(
      DemoRegistrationPolicy.demoBanner,
      allOf(contains('DEMO'), contains('simulated')),
    );
  });

  test('a minted DEMO code registers the device and says DEMO in every label', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    final String code = lane.demo.issueDemoCode();
    expect(code, matches(r'^\d{6}$'));

    final Result<RegistrationStatus> result =
        await lane.demo.submitPairingCode(code);
    final RegistrationStatus status = result.valueOrNull!;
    expect(result.isOk, isTrue);
    expect(status, isA<Registered>());
    expect(status.userLabel, contains('DEMO'));
    expect(
      (status as Registered).stableLocalId,
      'child-test-stable-id',
      reason: 'the id is minted by the injected minter, not by a server',
    );
    expect(
      lane.demo.audit.map((RegistrationAuditRow r) => r.kind).toList(),
      <RegistrationAuditKind>[
        RegistrationAuditKind.codeSubmitted,
        RegistrationAuditKind.demoAccepted,
      ],
    );
    expect(lane.demo.audit.first.at, RegistrationTestHarness.defaultStart);
  });

  test('the state stream carries every accepted move, in order', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    final List<String> seen = <String>[];
    final StreamSubscription<RegistrationStatus> sub = lane.demo.state
        .listen((RegistrationStatus s) => seen.add(s.kind.wire));

    final String code = lane.demo.issueDemoCode();
    await lane.demo.submitPairingCode(code);
    await lane.demo.unpair();
    // The revoked event is queued behind the awaited future; drain the queue
    // before cancelling or the listener never sees it.
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(seen, <String>['demoPending', 'registered', 'revoked']);
  });

  test('expiry: the 5-minute DEMO TTL is enforced by the injected clock', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    final String code = lane.demo.issueDemoCode();

    lane.advance(const Duration(minutes: 4, seconds: 59));
    expect(lane.demo.current, isA<Unregistered>());

    lane.advance(const Duration(seconds: 2));
    final Result<RegistrationStatus> late =
        await lane.demo.submitPairingCode(code);
    final RegistrationStatus status = late.valueOrNull!;
    expect(status, isA<Rejected>());
    expect(
      (status as Rejected).reason,
      RegistrationRejectReason.codeExpired,
      reason: 'D-3 option (ii): the DEMO keeps the 5 minutes the parent '
          'simulation already uses',
    );
    expect(status.userLabel, contains('DEMO'));
  });

  test('a code this DEMO never minted is refused, not accepted', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    lane.demo.issueDemoCode();
    final Result<RegistrationStatus> result =
        await lane.demo.submitPairingCode('000000');
    expect(
      (result.valueOrNull! as Rejected).reason,
      RegistrationRejectReason.codeMismatch,
    );
  });

  test('unpair is local, is audited, and never claims the parent was told', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    await lane.demo.submitPairingCode(lane.demo.issueDemoCode());

    final Result<RegistrationStatus> result = await lane.demo.unpair();
    final Revoked revoked = result.valueOrNull! as Revoked;
    expect(revoked.kind, RegistrationKind.revoked);
    expect(revoked.stableLocalId, 'child-test-stable-id');
    expect(revoked.userLabel, contains('DEMO'));
    expect(revoked.userLabel, isNot(contains('parent phone was notified')));
    expect(
      lane.demo.audit.last.note,
      DemoRegistrationPolicy.demoLandingNote,
    );

    // Only a registered device can be unpaired.
    expect((await lane.demo.unpair()).isErr, isTrue);
    expect(lane.demo.current, isA<Revoked>());
  });

  test('startOver clears the result but keeps the stable id and the audit', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    await lane.demo.submitPairingCode(lane.demo.issueDemoCode());
    await lane.demo.unpair();
    final int rows = lane.demo.audit.length;

    expect((await lane.demo.startOver()).isOk, isTrue);
    expect(lane.demo.current, isA<Unregistered>());
    expect(lane.demo.snapshot.stableLocalId, 'child-test-stable-id');
    expect(lane.demo.audit.length, rows + 1);
  });

  test('an in-memory-only DEMO still works and still records nothing secret', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness(persist: false);
    expect((await lane.demo.restore()).valueOrNull!.status, isA<Unregistered>());
    expect(
      (await lane.demo.submitPairingCode(lane.demo.issueDemoCode())).isOk,
      isTrue,
    );
    expect(lane.demo.audit, hasLength(2));
  });
}
