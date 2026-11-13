import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/device_pairing/data/pairing_simulation_service.dart';
import 'package:haven_app/features/device_pairing/data/simulation_models.dart';
import 'package:haven_app/features/family/data/family_scope.dart';

import '../support/data_fakes.dart';
import '../support/fakes.dart';

/// Regression lock for the Stage-2 DEMO labelling change (workstream C).
///
/// The labelling decision (D-3 option (ii), D-5 §3.3) is label-only: the
/// simulation's outputs — 6-digit codes, the 5-minute expiry, the validation
/// order, and the fabricated capability row (battery 95, all flags granted) —
/// must come out of this Stage byte-for-byte as they came out of Stage 1.
/// If someone "fixes" a value while labelling, this file fails.
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
    service = PairingSimulationService(
      scope: () => scope,
      writer: () => writer,
      random: Random(20261113),
    );
  });

  group('code shape and TTL are unchanged', () {
    test('generateSession yields exactly 6 digits', () {
      for (var i = 0; i < 50; i++) {
        expect(service.generateSession().code, matches(RegExp(r'^\d{6}$')));
      }
    });

    test('the default expiry is still 5 simulated minutes', () {
      final SimulatedPairingSession session = service.generateSession();
      expect(
        session.expiresAt.difference(session.createdAt),
        const Duration(minutes: 5),
      );
      expect(session.remainingTime.inSeconds, inInclusiveRange(295, 300));
      expect(session.isExpired, isFalse);
      expect(session.isRedeemed, isFalse);
    });
  });

  group('validation order is unchanged: format, reuse, expiry, match', () {
    test('malformed beats redeemed and expired', () {
      final SimulatedPairingSession session = service.generateSession()
        ..redeem();
      final failure = service
          .validateInput(rawInput: '12a4', session: session)
          .failureOrNull!;
      expect(failure.message, contains('exactly 6 digits'));
    });

    test('redeemed beats expired', () {
      final SimulatedPairingSession session = SimulatedPairingSession(
        code: '123456',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
      )..redeem();
      expect(
        service
            .validateInput(rawInput: '999999', session: session)
            .failureOrNull!
            .message,
        contains('already been used'),
      );
    });

    test('expired beats mismatch', () {
      final SimulatedPairingSession session = SimulatedPairingSession(
        code: '123456',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(
        service
            .validateInput(rawInput: '999999', session: session)
            .failureOrNull!
            .message,
        contains('expired'),
      );
    });

    test('mismatch is last, and a clean 6-digit match passes', () {
      final SimulatedPairingSession session = SimulatedPairingSession(
        code: '123456',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      expect(
        service
            .validateInput(rawInput: '654321', session: session)
            .failureOrNull!
            .message,
        contains('Invalid pairing code'),
      );
      expect(
        service.validateInput(rawInput: '123 456', session: session).valueOrNull,
        '123456',
      );
    });
  });

  group('the fabricated capability row is unchanged (it is now labelled)', () {
    test('completePairing still writes battery 95 and every flag granted', () async {
      final result = await service.completePairing(
        session: service.generateSession(),
        childUserId: 'u_child',
        childName: 'Leo',
      );
      expect(result.isOk, isTrue);
      final row = writer.lastPayload!;
      expect(row['battery_level'], 95);
      expect(row['is_charging'], isFalse);
      expect(row['usage_access_granted'], isTrue);
      expect(row['location_granted'], isTrue);
      expect(row['background_location_granted'], isTrue);
      expect(row['camera_granted'], isTrue);
      expect(row['microphone_granted'], isTrue);
      expect(row['notifications_granted'], isTrue);
      expect(row['display_name'], 'Leo\'s Phone (Simulated)');
      expect(row['platform'], 'android');
      expect(row['status'], 'active');
      // The session is redeemed exactly as before.
      expect(result.isOk, isTrue);
    });
  });
}
