import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';

import '../../child_devices/bindings/child_devices_bindings.dart';
import '../../family/bindings/family_bindings.dart';
import '../../safe_zones/bindings/zones_bindings.dart';
import '../controllers/dashboard_controller.dart';
import '../data/dashboard_repository.dart';
import '../data/local_dashboard_repository.dart';

/// DI for the parent dashboard.
abstract final class DashboardDependencies {
  static DashboardRepository ensureRepository() {
    if (!Get.isRegistered<DashboardRepository>()) {
      Get.put<DashboardRepository>(
        OfflineHavenBackend.isActive
            ? LocalDashboardRepository.live(
                family: FamilyDependencies.ensureRepository(),
                devices: ChildDevicesDependencies.ensureRepository,
                zones: SafeZonesDependencies.ensureRepository,
              )
            : HavenDashboardRepository(
                family: FamilyDependencies.ensureRepository(),
                rows: () => HavenBackend.rows,
              ),
        permanent: true,
      );
    }
    return Get.find<DashboardRepository>();
  }
}

final class DashboardBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<DashboardController>(
      DashboardController(repository: DashboardDependencies.ensureRepository()),
    );
  }
}
