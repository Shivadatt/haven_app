import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/core/permissions/admin_and_media_states.dart';
import 'package:haven_app/core/permissions/device_control_states.dart';
import 'package:haven_app/core/permissions/device_state_decoding.dart';

/// The two areas where the phone most often says nothing, and what that becomes.
///
/// Device-admin and location are the areas whose `null` fields are the normal answer
/// for an installed app, so the tests below are the record that a withheld reading is
/// kept withheld: it never becomes "no rules are in force", "no fix is possible" or a
/// position the phone never reported.
void main() {
  test(
    'a withheld restriction reading is not reported as "no rules in force"',
    () {
      final DeviceAdminStates withheld = decodeDeviceAdminStates(
        <String, Object?>{},
      );
      expect(withheld.restrictionsInForce, isNull);
      expect(withheld.canConfirmARestriction, isFalse);
      expect(withheld.restrictionLine, contains('will not tell an app'));

      final DeviceAdminStates none = decodeDeviceAdminStates(<String, Object?>{
        'restrictionsInForce': <Object?>[],
        'userRestrictionsReadable': true,
      });
      expect(none.restrictionsInForce, isEmpty);
      expect(none.canConfirmARestriction, isTrue);
      expect(none.restrictionLine, contains('no rules in force'));

      final DeviceAdminStates two = decodeDeviceAdminStates(<String, Object?>{
        'restrictionsInForce': <Object?>[
          'DISALLOW_ADD_USER',
          'DISALLOW_BLUETOOTH',
        ],
        'userRestrictionsReadable': true,
      });
      expect(two.restrictionLine, contains('2 rule(s) in force'));
      expect(two.restrictionLine, contains('DISALLOW_BLUETOOTH'));
    },
  );

  test(
    'admin standing is read from the phone, not from what this build wants',
    () {
      final DeviceAdminStates plain = decodeDeviceAdminStates(<String, Object?>{
        'serviceAvailable': true,
        'receiverDeclared': true,
        'adminActive': false,
        'deviceOwner': false,
        'activeAdminCount': 0,
        'storageEncryptionState': 'active',
      });
      expect(plain.standingLine, contains('is not an active device admin'));
      expect(plain.deviceOwner, isFalse);
      expect(
        plain.profileOwner,
        isNull,
        reason: 'never sent is not the same as no',
      );
      expect(plain.storageEncryptionState, 'active');

      // No service to ask means nothing else in the section can be claimed.
      final DeviceAdminStates none = decodeDeviceAdminStates(<String, Object?>{
        'serviceAvailable': false,
      });
      expect(none.serviceAvailable, isFalse);
      expect(none.adminActive, isFalse);
      expect(none.activeAdminCount, isNull);
    },
  );

  test(
    'a screen-timeout rule is only reported when the phone sent a number',
    () {
      expect(
        decodeDeviceAdminStates(<String, Object?>{}).screenLockTimeout,
        isNull,
      );
      expect(
        decodeDeviceAdminStates(<String, Object?>{
          'screenLockTimeoutMs': 60000,
        }).screenLockTimeout,
        const Duration(minutes: 1),
      );
      // A decimal through the channel is not an answer in milliseconds either.
      expect(
        decodeDeviceAdminStates(<String, Object?>{
          'screenLockTimeoutMs': 3.0,
        }).screenLockTimeout,
        isNull,
      );
      expect(
        decodeDeviceAdminStates(<String, Object?>{
          'adminActive': 1,
        }).adminActive,
        isFalse,
        reason: 'an int standing in for a bool is the phone not answering',
      );
    },
  );

  test("a location answer carries the phone's accuracy and no position", () {
    final LocationStates states = decodeLocationStates(<String, Object?>{
      'serviceAvailable': true,
      'gpsOn': true,
      'networkOn': false,
      'passiveOn': null,
      'lastFix': <String, Object?>{
        'provider': 'fused',
        'accuracyMetres': 47.2,
        'ageMs': 120000,
        'hasAltitude': false,
        'fromMockProvider': true,
      },
    });

    expect(states.providersOn, <String>['gps']);
    expect(states.fixLine, contains('2 minutes old'));
    expect(states.fixLine, contains('accurate to 47 m'));
    expect(states.fixLine, contains('flagged as a mock location'));
    expect(
      decodeLocationStates(<String, Object?>{
        'serviceAvailable': true,
        'lastFix': <String, Object?>{
          'provider': 'gps',
          'accuracyMetres': 9,
          'ageMs': 45000,
        },
      }).fixLine,
      contains('less than a minute'),
    );
  });

  test('a half-shaped fix is dropped rather than half-invented', () {
    final LocationStates states = decodeLocationStates(<String, Object?>{
      'serviceAvailable': true,
      'lastFix': <String, Object?>{'provider': 'gps', 'ageMs': 5000},
    });

    expect(states.lastFix, isNull);
    expect(states.fixLine, 'The phone is holding no fix right now.');
    expect(
      decodeLocationStates(<String, Object?>{
        'serviceAvailable': true,
        'lastFixWithheldBecause': 'permission',
      }).fixLine,
      contains('not allowed to ask for one'),
    );
    expect(
      decodeLocationStates(<String, Object?>{
        'serviceAvailable': false,
      }).fixLine,
      'This phone has no location service to ask.',
    );
  });

  test('a one-minute-old fix is pluralised the way it is said out loud', () {
    final LocationStates states = decodeLocationStates(<String, Object?>{
      'serviceAvailable': true,
      'lastFix': <String, Object?>{
        'provider': 'network',
        'accuracyMetres': 30,
        'ageMs': 60000,
      },
    });

    expect(states.fixLine, contains('1 minute old'));
    expect(states.fixLine, isNot(contains('1 minutes')));
    expect(
      decodeLocationStates(<String, Object?>{
        'serviceAvailable': true,
        'lastFix': <String, Object?>{
          'provider': 'gps',
          'accuracyMetres': 5,
          'ageMs': 86400000,
        },
      }).fixLine,
      contains('1 day old'),
    );
  });
}
