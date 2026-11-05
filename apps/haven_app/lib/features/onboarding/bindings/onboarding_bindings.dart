import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';

import '../../../core/storage/preferences_store.dart';
import '../../authentication/bindings/auth_bindings.dart';
import '../controllers/onboarding_controller.dart';
import '../data/local_onboarding_repository.dart';
import '../data/onboarding_repository.dart';

/// DI for first-run setup.
final class OnboardingBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OnboardingRepository>()) {
      // Offline writes the family rows directly; the edge function does not
      // exist on a phone with no backend.
      Get.put<OnboardingRepository>(
        OfflineHavenBackend.isActive
            ? LocalOnboardingRepository.live()
            : EdgeOnboardingRepository.live(),
        permanent: true,
      );
    }
    Get.put<OnboardingController>(
      OnboardingController(
        repository: Get.find<OnboardingRepository>(),
        auth: AuthDependencies.ensureRepository(),
        preferences: Get.isRegistered<PreferencesStore>()
            ? Get.find<PreferencesStore>()
            : null,
      ),
    );
  }
}
