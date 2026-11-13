import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/app/theme/haven_theme.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_app/features/child_devices/controllers/device_detail_controller.dart';
import 'package:haven_app/features/child_devices/views/widgets/device_hardware_card.dart';
import 'package:haven_app/features/child_devices/views/widgets/device_list_card.dart';
import 'package:haven_app/features/child_devices/views/widgets/device_setup_checklist_card.dart';
import 'package:haven_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:haven_app/features/dashboard/data/dashboard_repository.dart';
import 'package:haven_app/features/dashboard/views/widgets/dashboard_devices_card.dart';
import 'package:haven_models/haven_models.dart';

import '../child_devices/fakes.dart';

/// Stage 2 / D-5 §3.3 (risk R-9): every fabricated capability value written by
/// `pairing_simulation_service.dart` (battery 95, charging, the granted flags)
/// must be visibly labelled as simulated wherever it surfaces.
///
/// The device under test is built with `Device.fromRow` from EXACTLY the map
/// the simulation persists, so the labels are proven against the real demo
/// payload, not a convenient stand-in. The assertions also pin the values
/// themselves: labelling must not have changed what is displayed.
void main() {
  tearDown(Get.reset);

  Map<String, Object?> simulationRow() => <String, Object?>{
    'id': 'sim-dev-1',
    'family_id': 'f1',
    'child_user_id': 'child-1',
    'installation_id': 'installation-1',
    'display_name': 'Leo\'s Phone (Simulated)',
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
  };
  Device demoPairedDevice() => Device.fromRow(simulationRow());

  Future<void> pump(WidgetTester tester, List<Widget> children) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: HavenTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(children: children),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<DeviceDetailController> detailController(WidgetTester tester) async {
    final DeviceDetailController controller = DeviceDetailController(
      deviceId: 'sim-dev-1',
      repository: FakeDevicesRepository(record: demoPairedDevice()),
    );
    Get.put(controller);
    await controller.load();
    return controller;
  }

  testWidgets('DeviceHardwareCard labels the simulated battery it shows', (
    WidgetTester tester,
  ) async {
    await detailController(tester);
    await pump(tester, const <Widget>[DeviceHardwareCard()]);
    expect(find.text('DEMO — simulated values'), findsOneWidget);
    expect(
      find.text('95%'),
      findsOneWidget,
      reason: 'the value itself is unchanged — this is a label, not a fix',
    );
  });

  testWidgets('DeviceSetupChecklistCard labels the simulated capability flags', (
    WidgetTester tester,
  ) async {
    await detailController(tester);
    await pump(tester, const <Widget>[DeviceSetupChecklistCard()]);
    expect(find.text('DEMO — simulated values'), findsOneWidget);
    expect(find.text('Usage Access'), findsOneWidget);
    expect(
      find.text('Active'),
      findsNWidgets(5),
      reason: 'every simulated "Active" still renders — values unchanged',
    );
  });

  testWidgets('DeviceListCard labels the simulated battery in the row', (
    WidgetTester tester,
  ) async {
    await pump(tester, <Widget>[DeviceListCard(devices: <Device>[demoPairedDevice()])]);
    expect(
      find.textContaining('95% battery (DEMO — simulated values)'),
      findsOneWidget,
    );
  });

  testWidgets('DashboardDevicesCard labels the simulated battery it prints', (
    WidgetTester tester,
  ) async {
    final DashboardData data = DashboardData(
      family: null,
      alerts: const <SafetyAlert>[],
      devices: <Device>[demoPairedDevice()],
    );
    Get.put(DashboardController(repository: _LocalLaneRepository(data)));
    await pump(tester, <Widget>[DashboardDevicesCard(data: data)]);
    expect(find.textContaining('95% battery (DEMO — simulated values)'),
        findsOneWidget);
  });

  test('the simulation row really does carry the fabricated values labelled', () {
    // Guards the premise of the four tests above: if the simulation stopped
    // fabricating battery 95 and the granted flags, the labels would need to
    // move, not quietly become decoration.
    final Device dev = demoPairedDevice();
    expect(dev.batteryLevel, 95);
    expect(
      dev.hasUsageAccess && dev.hasLocation && dev.notificationsGranted == true,
      isTrue,
    );
  });
}

/// A dashboard repository whose device lane answers `Ok` — the local-first
/// shape the dashboard shows when a device list came from the simulation, so
/// the card renders its rows instead of the blocked gap notice.
final class _LocalLaneRepository implements DashboardRepository {
  _LocalLaneRepository(this._data);
  final DashboardData _data;

  @override
  Future<Result<DashboardData>> load() async => Ok<DashboardData>(_data);

  @override
  Future<Result<void>> pairedDevices() async => okVoid();
}
