import 'package:flutter_test/flutter_test.dart';

import 'package:haven_child/core/constants/child_config.dart';
import 'package:haven_child/core/device/device_fact_rows.dart';
import 'package:haven_child/core/device/device_information.dart';
import 'package:haven_child/core/device/fake_device_information.dart';
import 'package:haven_child/core/device/real_device_information.dart';

/// Brief §7: "device-information unavailable states (RealDeviceInformation
/// null handling + DeviceFacts 'Unavailable' fallbacks,
/// FakeDeviceInformation)".
void main() {
  group('RealDeviceInformation on this (non-Android) test host', () {
    final facts = const RealDeviceInformation().read();

    test('the two native-only fields are null, never guessed', () {
      expect(facts.model, isNull);
      expect(facts.manufacturer, isNull);
    });

    test('androidVersion is null off-device but the read never throws', () {
      // Platform.isAndroid is false on the test VM, so the guarded read
      // short-circuits; on a device it may answer — either way no crash.
      expect(facts.androidVersion, isNull);
    });

    test('identity fields are the single-sourced constants', () {
      expect(facts.appVersion, ChildConfig.appVersion);
      expect(facts.applicationId, ChildConfig.applicationId);
      expect(facts.applicationId, 'com.haven.child'); // decision D-1
      expect(facts.registrationStatus, RealDeviceInformation.notRegistered);
      expect(facts.registrationStatus, 'Not registered');
    });
  });

  test('DeviceFacts names the one fallback word', () {
    expect(DeviceFacts.unavailable, 'Unavailable');
  });

  group('DeviceFactRows fallbacks', () {
    test('null fields render the literal Unavailable, decided once centrally', () {
      final rows = DeviceFactRows.build(
        const DeviceFacts(
          appVersion: '0.1.0',
          applicationId: 'com.haven.child',
          registrationStatus: 'Not registered',
        ),
      );
      Map<String, String> byLabel() => {for (final r in rows) r.label: r.value};
      final values = byLabel();
      expect(values['Model'], 'Unavailable');
      expect(values['Manufacturer'], 'Unavailable');
      expect(values['Android version'], 'Unavailable');
      expect(values['App version'], '0.1.0');
      expect(values['App id'], 'com.haven.child');
      expect(values['Registration'], 'Not registered');
      expect(rows.where((r) => r.isUnavailable).length, 3);
    });

    test('a real read shows through unchanged — six fixed rows, in order', () {
      final rows = DeviceFactRows.build(
        const DeviceFacts(
          model: 'Pixel 9',
          manufacturer: 'Google',
          androidVersion: 'SDK 36, Android 16',
          appVersion: '0.1.0',
          applicationId: 'com.haven.child',
          registrationStatus: 'Not registered',
        ),
      );
      expect(rows.map((r) => r.label), [
        'Model',
        'Manufacturer',
        'Android version',
        'App version',
        'App id',
        'Registration',
      ]);
      expect(rows.first.value, 'Pixel 9');
      expect(rows.where((r) => r.isUnavailable), isEmpty);
    });

    test('the honest footnotes are stable copy the screens share', () {
      expect(DeviceFactRows.stageOneNote, contains('Unavailable'));
      expect(DeviceFactRows.registrationNote, contains('not registered'));
    });
  });

  group('FakeDeviceInformation mirrors the real build honesty', () {
    test('it never fabricates model or manufacturer', () {
      const fake = FakeDeviceInformation();
      final facts = fake.read();
      expect(facts.model, isNull);
      expect(facts.manufacturer, isNull);
      expect(facts.androidVersion, 'SDK 36, Android 16 (test)');
      expect(facts.appVersion, '0.1.0-test');
      final rows = DeviceFactRows.build(facts);
      // Exactly the two native-only fields fall back, no more.
      expect(rows.where((r) => r.isUnavailable).length, 2);
    });

    test('a test can also fake the android read away', () {
      final rows = DeviceFactRows.build(
        const FakeDeviceInformation(androidVersion: null).read(),
      );
      expect(
        rows.firstWhere((r) => r.label == 'Android version').isUnavailable,
        isTrue,
      );
    });
  });
}
