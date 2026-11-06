import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:haven_child/core/device/fake_device_information.dart';
import 'package:haven_child/core/device/real_device_information.dart';
import 'package:haven_child/features/device/controllers/device_info_controller.dart';
import 'package:haven_child/features/device/views/pages/device_page.dart';

import '../../support/host.dart';

/// `/device` (brief §7): six fact rows, real reads or the literal
/// "Unavailable", the honest footnotes, and nothing that pretends to work.
void main() {
  tearDown(() => Get.reset());

  Future<void> openDevice(
    WidgetTester tester, {
    FakeDeviceInformation? fake,
  }) async {
    Get.put<DeviceInfoController>(
      DeviceInfoController(device: fake ?? const FakeDeviceInformation()),
    );
    await tester.pumpWidget(childHost(const DevicePage()));
    await tester.pumpAndSettle();
  }

  testWidgets('every declared row is rendered with the fake reader', (tester) async {
    await openDevice(tester);
    for (final label in [
      'Model',
      'Manufacturer',
      'Android version',
      'App version',
      'App id',
      'Registration',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'missing row $label');
    }
    expect(find.text('SDK 36, Android 16 (test)'), findsOneWidget);
    expect(find.text('0.1.0-test'), findsOneWidget);
    expect(find.text('com.haven.child'), findsOneWidget);
  });

  testWidgets('the native-only fields say Unavailable, never a guess', (tester) async {
    await openDevice(tester);
    expect(find.text('Unavailable'), findsNWidgets(2)); // model + manufacturer
    expect(find.text(DevicePageNotes.forbiddenGuess), findsNothing);
  });

  testWidgets('registration reads the honest Stage-1 constant', (tester) async {
    await openDevice(tester);
    expect(find.text('Not registered'), findsOneWidget);
    expect(
      find.textContaining('Registration happens when a parent pairs'),
      findsOneWidget,
    );
  });

  testWidgets('the why-note and the no-buttons promise are both visible', (
    tester,
  ) async {
    await openDevice(tester);
    expect(find.text('Why some fields are unavailable'), findsOneWidget);
    expect(find.text('About registration'), findsOneWidget);
    expect(
      find.textContaining('no buttons that pretend to work'),
      findsOneWidget,
    );
    // And truly: the page has no interactive controls at all.
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('the REAL reader works on the host too: nulls fall back', (
    tester,
  ) async {
    // No fake here: RealDeviceInformation on the test VM, exactly as
    // registered by ChildInitialBindings.
    Get.put<DeviceInfoController>(
      DeviceInfoController(device: const RealDeviceInformation()),
    );
    await tester.pumpWidget(childHost(const DevicePage()));
    await tester.pumpAndSettle();
    expect(find.text('Unavailable'), findsNWidgets(3)); // + androidVersion
    expect(find.text('0.1.0'), findsOneWidget);
    expect(find.text('Not registered'), findsOneWidget);
  });

  testWidgets('the device screen fits a 320x568 phone', (tester) async {
    Get.put<DeviceInfoController>(
      DeviceInfoController(device: const FakeDeviceInformation()),
    );
    await pumpNarrow(tester, childHost(const DevicePage()));
    expect(tester.takeException(), isNull);
    expect(find.text('Model'), findsOneWidget);
  });
}

/// Strings a device screen must never print — an invented fact would match
/// one of these.
abstract final class DevicePageNotes {
  static const String forbiddenGuess = 'Pixel';
}
