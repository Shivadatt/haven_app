import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';

import '../../child_devices/bindings/child_devices_bindings.dart';
import '../../family/data/family_scope.dart';
import '../controllers/activity_controller.dart';
import '../data/activity_repository.dart';

/// DI for the usage screens.
///
/// The repository takes the device lane as a provider rather than building one:
/// naming a day-row needs `devices`, and whether that read answers or refuses is
/// decided by the device feature, not copied into this one.
abstract final class ActivityDependencies {
  static ActivityRepository ensureRepository() {
    if (!Get.isRegistered<ActivityRepository>()) {
      final FamilyScopeReader scope = FamilyScopeReader(
        auth: () => HavenBackend.auth,
        rows: () => HavenBackend.rows,
      );
      Get.put<ActivityRepository>(
        HavenActivityRepository(
          scope: () => scope,
          rows: () => HavenBackend.rows,
          devices: ChildDevicesDependencies.ensureRepository,
        ),
        permanent: true,
      );
    }
    return Get.find<ActivityRepository>();
  }
}

final class ActivityBindings extends Bindings {
  @override
  void dependencies() {
    // The contract gives this route a device id (`00-app-contract.md:162`). It is
    // taken from the argument, never from a widget, and an absent argument reads
    // the family instead.
    final Object? arg = Get.arguments;
    Get.put<ActivityController>(
      ActivityController(
        repository: ActivityDependencies.ensureRepository(),
        deviceId: arg is String ? arg : '',
      ),
    );
  }
}
