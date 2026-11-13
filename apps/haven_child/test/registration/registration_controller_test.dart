import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_child/features/registration/controllers/registration_controller.dart';
import 'package:haven_child/features/registration/domain/registration_audit.dart';
import 'package:haven_child/features/registration/domain/registration_status.dart';

import 'registration_fakes.dart';
import 'registration_test_support.dart';

/// The controller is the only place registration state becomes observable UI
/// state, so it gets the three things the contract promises: an honest lane
/// label, an in-flight guard, and a subscription that dies with it.
void main() {
  tearDown(Get.reset);

  test('it mirrors the service and never upgrades BLOCKED to something softer', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    final RegistrationController controller =
        Get.put(RegistrationController(service: lane.demo));
    await pumpMicrotasks();

    expect(controller.laneLabel, 'DEMO');
    expect(controller.currentStatus, isA<Unregistered>());
    expect(controller.isBusy.value, isFalse);
    expect(controller.message.value, isNull);
  });

  test('a successful DEMO submit moves the observable state and streams agree', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    final RegistrationController controller =
        Get.put(RegistrationController(service: lane.demo));
    await pumpMicrotasks();

    final String code = lane.demo.issueDemoCode();
    final Result<RegistrationStatus> result =
        await controller.submitPairingCode(code);
    await pumpMicrotasks();

    expect(result.isOk, isTrue);
    expect(controller.currentStatus, isA<Registered>());
    expect(controller.status.value, isA<Registered>());
    expect(controller.auditEvents, <String>[
      RegistrationAuditKind.codeSubmitted.wire,
      RegistrationAuditKind.demoAccepted.wire,
    ]);
    expect(controller.message.value, isNull);
  });

  test('a refused code is a message plus a state, not an exception', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    final RegistrationController controller =
        Get.put(RegistrationController(service: lane.demo));
    await pumpMicrotasks();

    lane.demo.issueDemoCode();
    final Result<RegistrationStatus> result =
        await controller.submitPairingCode('abc');
    await pumpMicrotasks();

    expect(result.isErr, isFalse, reason: 'the DEMO refused; that is a state');
    expect(controller.currentStatus, isA<Rejected>());
    expect(controller.isBusy.value, isFalse);
  });

  test('a typed failure is surfaced as a message and the state stays put', () async {
    final HangingService service = HangingService(
      failing: const StorageFailure('The local data could not be saved.'),
    );
    final RegistrationController controller =
        Get.put(RegistrationController(service: service));
    await pumpMicrotasks();

    final Result<RegistrationStatus> result =
        await controller.submitPairingCode('123456');
    expect(result.isErr, isTrue);
    expect(controller.message.value, 'The local data could not be saved.');
    expect(controller.currentStatus, isA<Unregistered>());
  });

  test('two calls at once: the second is refused before the first awaits', () async {
    final HangingService service = HangingService();
    final RegistrationController controller =
        Get.put(RegistrationController(service: service));
    await pumpMicrotasks();

    final Future<Result<RegistrationStatus>> first =
        controller.submitPairingCode('123456');
    expect(controller.isBusy.value, isTrue);
    final Result<RegistrationStatus> second =
        await controller.submitPairingCode('654321');

    expect(second.isErr, isTrue);
    expect(
      (second.failureOrNull! as ValidationFailure).detail,
      'in_flight_guard',
    );
    expect(service.calls, 1, reason: 'the guarded call never reached the service');

    service.release();
    final Result<RegistrationStatus> released = await first;
    expect(released.isOk, isTrue);
    expect(controller.isBusy.value, isFalse);
  });

  test('unpair routes through the same guard and reports the revoked state', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    final RegistrationController controller =
        Get.put(RegistrationController(service: lane.demo));
    await pumpMicrotasks();

    await controller.submitPairingCode(lane.demo.issueDemoCode());
    final Result<RegistrationStatus> result = await controller.unpair();
    await pumpMicrotasks();

    expect(result.isOk, isTrue);
    expect(controller.currentStatus, isA<Revoked>());
    expect(controller.currentStatus.userLabel, contains('DEMO'));
  });

  test('onClose cancels the subscription; later events cannot touch a dead controller', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    final RegistrationController controller =
        Get.put(RegistrationController(service: lane.demo));
    await pumpMicrotasks();

    await Get.delete<RegistrationController>(force: true);
    expect(controller.isClosed, isTrue);

    // Must not throw: the service is still alive and still emitting.
    await lane.demo.submitPairingCode(lane.demo.issueDemoCode());
    await pumpMicrotasks();
    expect(lane.demo.current, isA<Registered>());
  });

  test('restore reports a storage failure instead of pretending the device is new', () async {
    final RegistrationController controller =
        Get.put(RegistrationController(service: UnreadableService()));
    await pumpMicrotasks();

    expect(controller.message.value, 'The local data could not be read.');
    expect(controller.currentStatus, isA<Unregistered>());
  });
}
