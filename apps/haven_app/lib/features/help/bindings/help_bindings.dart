import 'package:get/get.dart';
import '../controllers/faq_controller.dart';
import '../controllers/help_controller.dart';
import '../controllers/support_controller.dart';
import '../data/help_repository.dart';
import '../data/local_support_repository.dart';

abstract final class HelpDependencies {
  static HelpRepository ensureRepository() {
    if (!Get.isRegistered<HelpRepository>()) {
      Get.put<HelpRepository>(
        LocalSupportRepository(),
        permanent: true,
      );
    }
    return Get.find<HelpRepository>();
  }
}

final class HelpCenterBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HelpController>(
      () => HelpController(repository: HelpDependencies.ensureRepository()),
    );
  }
}

final class FaqBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FaqController>(
      () => FaqController(repository: HelpDependencies.ensureRepository()),
    );
  }
}

final class ContactSupportBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupportController>(
      () => SupportController(repository: HelpDependencies.ensureRepository()),
    );
  }
}
