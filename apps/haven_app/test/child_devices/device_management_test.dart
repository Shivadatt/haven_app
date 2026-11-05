import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_app/features/child_devices/controllers/device_detail_controller.dart';
import 'package:haven_app/features/child_devices/controllers/devices_controller.dart';
import 'package:haven_app/features/child_devices/views/pages/device_detail_page.dart';
import 'package:haven_app/features/child_devices/views/pages/devices_page.dart';
import 'package:haven_app/features/child_devices/views/widgets/device_list_card.dart';
import 'package:haven_app/features/telemetry/controllers/telemetry_controller.dart';

import '../telemetry/fakes.dart';
import 'fakes.dart';

void main() {
  tearDown(Get.reset);

  group('Device Management', () {
    test('DevicesController.addDevice creates device and reloads list', () async {
      final repo = FakeDevicesRepository(devices: []);
      final controller = DevicesController(repository: repo);
      await controller.load();
      expect(controller.devices.value!.valueOrNull!, isEmpty);

      final result = await controller.addDevice(
        displayName: 'My Tablet',
        childUserId: 'c1',
        platform: 'android',
        batteryLevel: 95,
      );

      expect(result.isOk, isTrue);
      expect(controller.devices.value!.valueOrNull!.length, 1);
      expect(controller.devices.value!.valueOrNull!.first.displayName, 'My Tablet');
    });

    testWidgets('DeviceListCard renders SIMULATED DEVICE chip and battery level', (tester) async {
      final simulated = device(
        'd1',
        name: 'Pixel Sim',
        batteryLevel: 88,
        installationId: 'sim-d1',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: HavenTheme.light,
          home: Scaffold(body: DeviceListCard(devices: [simulated])),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pixel Sim'), findsOneWidget);
      expect(find.text('SIMULATED DEVICE'), findsOneWidget);
      expect(find.textContaining('88% battery'), findsOneWidget);
    });

    test('DeviceDetailController rename updates display name', () async {
      final repo = FakeDevicesRepository(
        record: device('d1', name: 'Original Name'),
      );
      final controller = DeviceDetailController(deviceId: 'd1', repository: repo);
      await controller.load();

      final ok = await controller.rename('Renamed Phone');
      expect(ok, isTrue);
      expect(repo.lastRenamedId, 'd1');
      expect(repo.lastNewName, 'Renamed Phone');
      expect(controller.device.value!.valueOrNull!.displayName, 'Renamed Phone');
    });

    test('DeviceDetailController assignChild updates assigned child', () async {
      final repo = FakeDevicesRepository(
        record: device('d1', childUserId: 'c1'),
      );
      final controller = DeviceDetailController(deviceId: 'd1', repository: repo);
      await controller.load();

      final ok = await controller.assignChild('c2');
      expect(ok, isTrue);
      expect(repo.lastAssignedChildUserId, 'c2');
      expect(controller.device.value!.valueOrNull!.childUserId, 'c2');
    });

    testWidgets('DevicesPage has Add simulated device button', (tester) async {
      final repo = FakeDevicesRepository(devices: []);
      Get.put<DevicesController>(DevicesController(repository: repo));

      await tester.pumpWidget(
        GetMaterialApp(theme: HavenTheme.light, home: const DevicesPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add simulated device'), findsOneWidget);
    });

    testWidgets('DeviceDetailPage shows Rename and Assign child buttons', (tester) async {
      final repo = FakeDevicesRepository(
        record: device('d1', name: 'Test Device', installationId: 'sim-d1'),
      );
      // Pretend offline where revoke is not blocked
      repo.revokeFailWith = null;
      Get.put<DeviceDetailController>(
        DeviceDetailController(deviceId: 'd1', repository: repo),
      );
      Get.put<TelemetryController>(
        TelemetryController(
          repository: FakeTelemetryRepository(),
          deviceId: 'd1',
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(theme: HavenTheme.light, home: const DeviceDetailPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Device'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Assign child'), findsOneWidget);
    });
  });
}
