import 'dart:math';

import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import '../../family/data/family_scope.dart';
import 'simulation_models.dart';

/// Service managing pairing code generation, validation, and local device creation.
final class PairingSimulationService {
  PairingSimulationService({
    required this.scope,
    required this.writer,
    Random? random,
  }) : random = random ?? Random.secure();

  final FamilyScopeReader Function() scope;
  final RowWriter Function() writer;
  final Random random;

  /// Generates a 6-digit pairing code with a 5-minute expiry countdown.
  SimulatedPairingSession generateSession({Duration expiry = const Duration(minutes: 5)}) {
    final int number = random.nextInt(1000000);
    final String code = number.toString().padLeft(6, '0');
    final DateTime now = DateTime.now();
    return SimulatedPairingSession(
      code: code,
      createdAt: now,
      expiresAt: now.add(expiry),
    );
  }

  /// Validates format, expiry, matching, and reuse prevention.
  Result<String> validateInput({
    required String? rawInput,
    required SimulatedPairingSession session,
  }) {
    final String input = (rawInput ?? '')
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .trim();

    if (input.length != 6 || !RegExp(r'^\d{6}$').hasMatch(input)) {
      return const Err<String>(
        ValidationFailure(
          'Pairing code must be exactly 6 digits.',
          field: 'pairing_code',
        ),
      );
    }

    if (session.isRedeemed) {
      return const Err<String>(
        ValidationFailure(
          'This pairing code has already been used.',
          field: 'pairing_code',
        ),
      );
    }

    if (session.isExpired) {
      return const Err<String>(
        ValidationFailure(
          'Pairing code has expired. Please generate a new code.',
          field: 'pairing_code',
        ),
      );
    }

    if (input != session.code) {
      return const Err<String>(
        ValidationFailure(
          'Invalid pairing code. Please check and try again.',
          field: 'pairing_code',
        ),
      );
    }

    return Ok<String>(input);
  }

  /// Pairs the simulated device and creates the record in `TableName.devices`.
  Future<Result<SimulatedDevice>> completePairing({
    required SimulatedPairingSession session,
    required String childUserId,
    required String childName,
    String? customDisplayName,
  }) async {
    final Result<FamilyScope> scopeRes = await scope().resolve();
    final FamilyScope? mine = scopeRes.valueOrNull;
    if (mine == null) return Err<SimulatedDevice>(scopeRes.failureOrNull!);

    if (childUserId.isEmpty) {
      return const Err<SimulatedDevice>(
        ValidationFailure('Select a child to associate with this device.', field: 'child_id'),
      );
    }

    final String deviceId = LocalIds.create();
    final String now = DateTime.now().toUtc().toIso8601String();
    final String name = (customDisplayName != null && customDisplayName.trim().isNotEmpty)
        ? customDisplayName.trim()
        : "$childName's Phone (Simulated)";

    final Map<String, Object?> row = <String, Object?>{
      'id': deviceId,
      'family_id': mine.familyId,
      'child_user_id': childUserId,
      'installation_id': LocalIds.create(),
      'display_name': name,
      'platform': 'android',
      'enforcement_mode': 'device_owner',
      'policy_version': 1,
      'status': 'active',
      'battery_level': 95,
      'is_charging': false,
      'usage_access_granted': true,
      'location_granted': true,
      'background_location_granted': true,
      'camera_granted': true,
      'microphone_granted': true,
      'notifications_granted': true,
      'created_at': now,
      'updated_at': now,
    };

    final Result<void> inserted = await writer().insert(TableName.devices, row);
    if (inserted.isErr) return Err<SimulatedDevice>(inserted.failureOrNull!);

    session.redeem();

    return Ok<SimulatedDevice>(
      SimulatedDevice(
        id: deviceId,
        familyId: mine.familyId,
        childUserId: childUserId,
        childName: childName,
        displayName: name,
        platform: 'android',
        status: 'active',
        pairedAt: DateTime.now(),
      ),
    );
  }
}
