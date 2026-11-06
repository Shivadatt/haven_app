import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../core/device/device_information.dart';
import '../../../core/session/child_local_session.dart';
import '../../../core/storage/child_profile_repository.dart';
import '../../../core/storage/onboarding_state_store.dart';
import '../controllers/onboarding_controller.dart';
import '../services/onboarding_completion.dart';

/// DI for the setup flow. Everything it needs is already permanent —
/// storage lanes by `ChildInitialBindings.startStorage`, the device reader
/// by `register` — so this binding only composes the controller.
final class OnboardingBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<OnboardingController>(
      OnboardingController(
        drafts: Get.find<OnboardingStateStore>(),
        completion: OnboardingCompletion(
          profiles: Get.find<ChildProfileRepository>(),
          sessions: Get.find<ChildSessionStore>(),
          drafts: Get.find<OnboardingStateStore>(),
          clock: systemClock,
        ),
        device: Get.find<DeviceInformation>(),
        push: (route) => Get.toNamed(route),
        finishRoute: (route) => Get.offNamed(route),
      ),
    );
  }
}
