import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';

import '../../telemetry/bindings/telemetry_dependencies.dart';
import '../controllers/device_detail_controller.dart';
import '../controllers/devices_controller.dart';
import '../data/device_route_args.dart';
import '../data/devices_repository.dart';
import '../data/local_devices_repository.dart';

/// DI for the device screens.
///
/// The repository is registered even though every cloud call it makes is a
/// refusal: the screens read their own copy from it, so the sentence a parent
/// sees stays owned by the data layer and cannot drift into a widget. Offline,
/// the same interface reads and writes `devices` rows on this phone.
abstract final class ChildDevicesDependencies {
  static DevicesRepository ensureRepository() {
    if (!Get.isRegistered<DevicesRepository>()) {
      Get.put<DevicesRepository>(
        OfflineHavenBackend.isActive
            ? LocalDevicesRepository.live()
            : HavenDevicesRepository(),
        permanent: true,
      );
    }
    return Get.find<DevicesRepository>();
  }
}

final class DevicesBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<DevicesController>(
      DevicesController(
        repository: ChildDevicesDependencies.ensureRepository(),
      ),
    );
  }
}

/// The detail page reads its subject from a typed route argument, so a link that
/// passes anything else lands on "no device was named" rather than on a device
/// the parent never chose.
final class DeviceDetailBindings extends Bindings {
  @override
  void dependencies() {
    final DeviceRouteArgs? args = DeviceRouteArgs.tryParse(Get.arguments);
    final String deviceId = args?.deviceId ?? '';
    Get.put<DeviceDetailController>(
      DeviceDetailController(
        deviceId: deviceId,
        repository: ChildDevicesDependencies.ensureRepository(),
      ),
    );
    // Telemetry has no route of its own, so its card is mounted here — and its
    // controller has to exist before the page reads it.
    TelemetryDependencies.ensureController(deviceId);
  }
}
