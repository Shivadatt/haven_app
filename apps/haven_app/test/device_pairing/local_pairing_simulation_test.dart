import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/device_pairing/controllers/pairing_simulation_controller.dart';
import 'package:haven_app/features/device_pairing/data/pairing_simulation_service.dart';
import 'package:haven_app/features/device_pairing/data/simulation_models.dart';
import 'package:haven_app/features/family/data/family_models.dart';
import 'package:haven_app/features/family/data/family_scope.dart';
import 'package:haven_models/haven_models.dart';

import '../family/fakes.dart';
import '../support/data_fakes.dart';
import '../support/fakes.dart';

void main() {
  late FakeRowWriter writer;
  late PairingSimulationService service;

  final auth = FakeUserAuth(
    const AuthSession(
      userId: 'u_parent',
      email: 'parent@haven.test',
      accessToken: 'token',
    ),
  );

  final rows = FakeRowReader({
    TableName.familyMembers: [
      {
        'id': 'm1',
        'family_id': 'f_test',
        'user_id': 'u_parent',
        'role': 'parent',
        'status': 'active',
        'created_at': '2026-01-01T00:00:00Z',
      },
    ],
  });

  final scope = FamilyScopeReader(auth: () => auth, rows: () => rows);

  setUp(() {
    writer = FakeRowWriter();
    service = PairingSimulationService(scope: () => scope, writer: () => writer);
  });

  group('PairingSimulationService - Code Generation & Countdown', () {
    test('generates a 6-digit numeric pairing code with 5-minute expiry', () {
      final session = service.generateSession();
      expect(session.code.length, 6);
      expect(int.tryParse(session.code), isNotNull);
      expect(session.isExpired, isFalse);
      expect(session.isRedeemed, isFalse);
      expect(session.isValid, isTrue);
      expect(session.remainingTime.inSeconds, inInclusiveRange(295, 300));
    });
  });

  group('PairingSimulationService - Code Validation', () {
    test('validates 6-digit format and rejects invalid formats', () {
      final session = service.generateSession();
      expect(service.validateInput(rawInput: '123', session: session).isErr, isTrue);
      expect(service.validateInput(rawInput: 'abcdef', session: session).isErr, isTrue);
      expect(service.validateInput(rawInput: '1234567', session: session).isErr, isTrue);
    });

    test('rejects wrong pairing code', () {
      final session = SimulatedPairingSession(
        code: '123456',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      final res = service.validateInput(rawInput: '654321', session: session);
      expect(res.isErr, isTrue);
      expect(res.failureOrNull?.message, contains('Invalid pairing code'));
    });

    test('rejects expired pairing code', () {
      final expiredSession = SimulatedPairingSession(
        code: '123456',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      final res = service.validateInput(rawInput: '123456', session: expiredSession);
      expect(res.isErr, isTrue);
      expect(res.failureOrNull?.message, contains('expired'));
    });

    test('prevents code reuse after successful pairing', () {
      final session = service.generateSession();
      session.redeem();
      final res = service.validateInput(rawInput: session.code, session: session);
      expect(res.isErr, isTrue);
      expect(res.failureOrNull?.message, contains('already been used'));
    });

    test('accepts valid code ignoring spaces and hyphens', () {
      final session = SimulatedPairingSession(
        code: '123456',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      final res = service.validateInput(rawInput: '123-456', session: session);
      expect(res.isOk, isTrue);
      expect(res.valueOrNull, '123456');
    });
  });

  group('PairingSimulationService - Device Creation', () {
    test('creates simulated device in TableName.devices linked to child', () async {
      final session = service.generateSession();
      final result = await service.completePairing(
        session: session,
        childUserId: 'u_child_ivy',
        childName: 'Ivy',
      );

      expect(result.isOk, isTrue);
      final device = result.valueOrNull!;
      expect(device.childUserId, 'u_child_ivy');
      expect(device.childName, 'Ivy');
      expect(device.status, 'active');
      expect(device.platform, 'android');
      expect(session.isRedeemed, isTrue);

      final insertPayload = writer.lastPayload!;
      expect(insertPayload['family_id'], 'f_test');
      expect(insertPayload['child_user_id'], 'u_child_ivy');
      expect(insertPayload['status'], 'active');
      expect(insertPayload['location_granted'], isTrue);
    });
  });

  group('PairingSimulationController - State & Lifecycle', () {
    test('generateCode, submitCode, cancelSimulation and reset flows', () async {
      final fakeFamily = FakeFamilyRepository(
        bundle: FamilyBundle(
          family: const Family(
            id: 'f_test',
            name: 'Rivera',
            ownerId: 'u_parent',
            settings: {},
          ),
          parents: const [],
          children: [child('u_ivy', 'Ivy')],
        ),
      );

      final controller = PairingSimulationController(
        service: service,
        family: fakeFamily,
      );
      await controller.load();

      expect(controller.children.length, 1);
      expect(controller.selectedChild.value?.name, 'Ivy');

      controller.generateCode();
      expect(controller.session.value, isNotNull);
      final code = controller.session.value!.code;

      controller.codeController.text = code;
      await controller.submitCode();

      expect(controller.createdDevice.value, isNotNull);
      expect(controller.createdDevice.value?.childName, 'Ivy');

      controller.reset();
      expect(controller.createdDevice.value, isNull);
      expect(controller.session.value, isNull);
    });
  });
}
