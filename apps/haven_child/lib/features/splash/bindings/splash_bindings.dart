import 'package:get/get.dart';

import '../../../app/bindings/child_initial_bindings.dart';
import '../../../core/session/child_local_session.dart';
import '../../../core/storage/child_data_resetter.dart';
import '../../../core/storage/child_profile_repository.dart';
import '../controllers/splash_controller.dart';

/// DI for the boot screen. The providers only run after `openStorage` has
/// succeeded — see the controller comment — so `Get.find` here is safe by
/// sequencing, and a test can hand the controller pure functions instead.
final class SplashBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<SplashController>(
      SplashController(
        openStorage: () => ChildInitialBindings.startStorage(),
        resetStorage: () => ChildDataResetter.clearAll(
          verifyReadableFirst: false,
        ),
        profileRepository: () => Get.find<ChildProfileRepository>(),
        sessionStore: () => Get.find<ChildSessionStore>(),
        navigate: (route) => Get.offNamed(route),
      ),
    );
  }
}
