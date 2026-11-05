import 'package:get/get.dart';

import '../controllers/child_create_controller.dart';
import 'family_bindings.dart';

/// Bindings for the standalone child creation screen.
final class ChildCreateBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChildCreateController>(
      () => ChildCreateController(
        repository: FamilyDependencies.ensureRepository(),
      ),
    );
  }
}
