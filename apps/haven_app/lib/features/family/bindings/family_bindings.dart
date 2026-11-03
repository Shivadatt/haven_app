import 'package:get/get.dart';

import '../controllers/child_profile_controller.dart';
import '../controllers/family_controller.dart';
import '../data/family_repository.dart';

/// DI for the family screens.
abstract final class FamilyDependencies {
  static FamilyRepository ensureRepository() {
    if (!Get.isRegistered<FamilyRepository>()) {
      Get.put<FamilyRepository>(HavenFamilyRepository.live(), permanent: true);
    }
    return Get.find<FamilyRepository>();
  }
}

final class FamilyBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<FamilyController>(
      FamilyController(repository: FamilyDependencies.ensureRepository()),
    );
  }
}

/// The child page takes its subject from the route argument, because the family
/// list is the only place that knows who is in the family.
final class ChildProfileBindings extends Bindings {
  @override
  void dependencies() {
    final Object? arg = Get.arguments;
    Get.put<ChildProfileController>(
      ChildProfileController(
        childUserId: arg is String ? arg : '',
        repository: FamilyDependencies.ensureRepository(),
      ),
    );
  }
}
