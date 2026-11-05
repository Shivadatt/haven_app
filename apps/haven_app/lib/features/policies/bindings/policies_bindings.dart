import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';

import '../../child_devices/bindings/child_devices_bindings.dart';
import '../../family/data/family_scope.dart';
import '../controllers/policies_controller.dart';
import '../data/local_policies_repository.dart';
import '../data/policies_repository.dart';

/// DI for the rules screens.
///
/// The device lane is supplied as a provider because naming the device a version
/// was written for needs `devices`, and whether that read answers or refuses is
/// the device feature's answer — this screen repeats it rather than paraphrasing.
abstract final class PoliciesDependencies {
  static PoliciesRepository ensureRepository() {
    if (!Get.isRegistered<PoliciesRepository>()) {
      final FamilyScopeReader scope = FamilyScopeReader(
        auth: () => HavenBackend.auth,
        rows: () => HavenBackend.rows,
      );
      Get.put<PoliciesRepository>(
        OfflineHavenBackend.isActive
            ? LocalPoliciesRepository.live()
            : HavenPoliciesRepository(
                scope: () => scope,
                rows: () => HavenBackend.rows,
                devices: ChildDevicesDependencies.ensureRepository,
              ),
        permanent: true,
      );
    }
    return Get.find<PoliciesRepository>();
  }
}

final class PoliciesBindings extends Bindings {
  @override
  void dependencies() {
    // The contract gives this route a device id (`00-app-contract.md:161`).
    final Object? arg = Get.arguments;
    Get.put<PoliciesController>(
      PoliciesController(
        repository: PoliciesDependencies.ensureRepository(),
        deviceId: arg is String ? arg : '',
      ),
    );
  }
}
