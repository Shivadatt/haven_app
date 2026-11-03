import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

/// A full `devices` row as the dashboard capture lists it (25 columns).
Map<String, Object?> _deviceRow() => {
  'id': '2f2fa0a4-6f1c-4c2a-8f83-9a1c1b6d0e01',
  'family_id': '2f2fa0a4-6f1c-4c2a-8f83-9a1c1b6d0e02',
  'child_user_id': '2f2fa0a4-6f1c-4c2a-8f83-9a1c1b6d0e03',
  'installation_id': 'install-000001',
  'display_name': "Aanya's phone",
  'platform': 'android',
  'android_version': '14',
  'app_version': '1.2.0',
  'status': 'active',
  'secret_hash': null,
  'credential_issued_at': '2026-11-01T09:00:00.000Z',
  'credential_revoked_at': null,
  'last_seen_at': '2026-11-03T06:15:00.000Z',
  'battery_level': 82,
  'is_charging': false,
  'enforcement_mode': 'device_admin',
  'policy_version': 4,
  'usage_access_granted': true,
  'location_granted': true,
  'background_location_granted': false,
  'camera_granted': false,
  'microphone_granted': false,
  'notifications_granted': true,
  'created_at': '2026-10-30T11:00:00.000Z',
  'updated_at': '2026-11-03T06:15:00.000Z',
};

void main() {
  group('Device', () {
    test('reads every captured column', () {
      final d = Device.fromRow(_deviceRow());
      expect(d.id, '2f2fa0a4-6f1c-4c2a-8f83-9a1c1b6d0e01');
      expect(d.displayName, "Aanya's phone");
      expect(d.deviceStatus, DeviceStatus.active);
      expect(d.mode, EnforcementMode.deviceAdmin);
      expect(d.policyVersion, 4);
      expect(d.hasBackgroundLocation, isFalse);
      expect(d.isUsable, isTrue);
      expect(d.credentialIssuedAt, DateTime.utc(2026, 11, 1, 9));
      expect(d.batteryLevel, 82);
    });

    test('an unknown status token is null, never a guess', () {
      final d = Device.fromRow({..._deviceRow(), 'status': 'sleeping'});
      expect(d.deviceStatus, isNull);
      expect(d.isUsable, isFalse);
    });

    test('a revoked device with a null secret is not usable', () {
      final d = Device.fromRow({
        ..._deviceRow(),
        'status': 'revoked',
        'secret_hash': null,
      });
      expect(d.deviceStatus, DeviceStatus.revoked);
      expect(d.isUsable, isFalse);
    });

    test('missing nullable columns do not throw', () {
      final d = Device.fromRow({
        'id': 'x',
        'family_id': 'y',
        'child_user_id': 'z',
      });
      expect(d.lastSeenAt, isNull);
      expect(d.batteryLevel, isNull);
      expect(d.policyVersion, 0);
    });
  });

  group('RPC params', () {
    test('names match the captured signatures exactly', () {
      expect(
        const CreateFamilyWithOwnerArgs(owner: 'o', name: 'N').toParams(),
        {'p_owner': 'o', 'p_name': 'N'},
      );
      expect(
        const UnlinkChildArgs(
          familyId: 'f',
          childUserId: 'c',
          actorUserId: 'a',
        ).toParams().keys,
        orderedEquals(['p_family_id', 'p_child_user_id', 'p_actor_user_id']),
      );
      expect(const PollDeviceCommandsArgs(deviceId: 'd', limit: 5).toParams(), {
        'p_device_id': 'd',
        'p_limit': 5,
      });
      expect(const DetectOfflineDevicesArgs().toParams(), isEmpty);
      expect(const ExpireStaleSessionsArgs().toParams(), isEmpty);
    });

    test('timestamps are written as ISO-8601 UTC and dates round-trip', () {
      final p = CreatePairingRequestArgs(
        childUserId: 'c',
        familyId: 'f',
        parentUserId: 'p',
        tokenId: 't',
        expiresAt: DateTime.utc(2026, 11, 3, 7),
      ).toParams();
      expect(p['p_expires_at'], '2026-11-03T07:00:00.000Z');
      expect(asDate(p['p_expires_at']), DateTime.utc(2026, 11, 3, 7));
      expect(toJsonDate(null), isNull);
    });
  });
}
