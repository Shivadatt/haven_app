import 'package:get/get.dart';

import '../../authentication/bindings/auth_bindings.dart';
import '../controllers/onboarding_controller.dart';
import '../data/onboarding_repository.dart';

/// DI for first-run setup.
final class OnboardingBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OnboardingRepository>()) {
      Get.put<OnboardingRepository>(
        EdgeOnboardingRepository.live(),
        permanent: true,
      );
    }
    Get.put<OnboardingController>(
      OnboardingController(
        repository: Get.find<OnboardingRepository>(),
        auth: AuthDependencies.ensureRepository(),
      ),
    );
  }
}
