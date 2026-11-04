import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/child_devices/controllers/device_detail_controller.dart';
import 'package:haven_app/features/child_devices/controllers/devices_controller.dart';
import 'package:haven_app/features/child_devices/views/pages/device_detail_page.dart';
import 'package:haven_app/features/child_devices/views/pages/devices_page.dart';
import 'package:haven_app/features/telemetry/controllers/telemetry_controller.dart';

import '../telemetry/fakes.dart';
import 'fakes.dart';

/// How a device page test gets onto the page and moves around it.
///
/// [routes] records which verb each navigation used, because "opens on top" and
/// "replaces the stack" are different promises to a parent.
final class DevicesDriver {
  final List<(String, String, Object?)> routes = <(String, String, Object?)>[];
  late FakeDevicesRepository repository;

  Future<void> openList(
    WidgetTester tester, {
    FakeDevicesRepository? repo,
  }) async {
    routes.clear();
    repository = repo ?? FakeDevicesRepository();
    Get.put<DevicesController>(
      DevicesController(
        repository: repository,
        push: (String route, Object? arg) => routes.add(('push', route, arg)),
      ),
    );
    await pump(tester, const DevicesPage());
  }

  Future<void> openDetail(
    WidgetTester tester, {
    String deviceId = 'd1',
    FakeDevicesRepository? repo,
  }) async {
    routes.clear();
    repository = repo ?? FakeDevicesRepository();
    Get.put<DeviceDetailController>(
      DeviceDetailController(deviceId: deviceId, repository: repository),
    );
    // The detail page mounts the trail card, and the binding that puts its
    // controller is not used here, so the driver puts it. An unseeded trail
    // refuses, which is the honest state for a device test.
    Get.put<TelemetryController>(
      TelemetryController(
        repository: FakeTelemetryRepository(),
        deviceId: deviceId,
      ),
    );
    await pump(tester, const DeviceDetailPage());
  }

  Future<void> pump(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      GetMaterialApp(theme: HavenTheme.light, home: page),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(
    WidgetTester tester,
    String label, {
    Type buttonType = FilledButton,
  }) async {
    final Finder action = find.descendant(
      of: find.byType(buttonType),
      matching: find.text(label),
    );
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
  }

  /// Only the fake's own refusal words are used by these tests, so a screen that
  /// paraphrases the gap instead of rendering it fails.
  static const String listGap = 'no contract for listing devices';
  static const String recordGap = 'no contract for reading a device';
}
