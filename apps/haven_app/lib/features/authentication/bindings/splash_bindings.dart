import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';

import '../../../app/bindings/initial_bindings.dart';
import '../controllers/splash_controller.dart';

/// DI for the first screen. Nothing here waits on the network: the controller
/// awaits the backend install and reports what it finds.
final class SplashBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<SplashController>(
      SplashController(
        connect: InitialBindings.startBackend,
        auth: () => HavenBackend.auth,
        profiles: () => HavenBackend.profiles,
      ),
    );
  }
}
