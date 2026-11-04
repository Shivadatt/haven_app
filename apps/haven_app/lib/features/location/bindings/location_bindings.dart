import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';

import '../../child_devices/bindings/child_devices_bindings.dart';
import '../../family/data/family_scope.dart';
import '../controllers/location_controller.dart';
import '../data/location_repository.dart';

/// DI for the location screens.
///
/// The device lane is supplied as a provider because naming a fix needs
/// `devices`, and whether that read answers or refuses is the device feature's
/// answer — this screen repeats it rather than paraphrasing it.
abstract final class LocationDependencies {
  static LocationRepository ensureRepository() {
    if (!Get.isRegistered<LocationRepository>()) {
      final FamilyScopeReader scope = FamilyScopeReader(
        auth: () => HavenBackend.auth,
        rows: () => HavenBackend.rows,
      );
      Get.put<LocationRepository>(
        HavenLocationRepository(
          scope: () => scope,
          rows: () => HavenBackend.rows,
          devices: ChildDevicesDependencies.ensureRepository,
        ),
        permanent: true,
      );
    }
    return Get.find<LocationRepository>();
  }
}

final class LocationBindings extends Bindings {
  @override
  void dependencies() {
    // The contract gives this route a device id (`00-app-contract.md:162`).
    final Object? arg = Get.arguments;
    Get.put<LocationController>(
      LocationController(
        repository: LocationDependencies.ensureRepository(),
        deviceId: arg is String ? arg : '',
      ),
    );
  }
}
