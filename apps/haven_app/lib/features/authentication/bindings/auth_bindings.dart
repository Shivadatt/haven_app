import 'package:get/get.dart';

import '../controllers/register_controller.dart';
import '../controllers/sign_in_controller.dart';
import '../data/auth_repository.dart';

/// Identity DI. The repository is registered once and is permanent: sign-in,
/// registration and sign-out all describe the same session, and splitting them
/// across three instances would let two screens disagree about who is signed in.
abstract final class AuthDependencies {
  static AuthRepository ensureRepository() {
    if (!Get.isRegistered<AuthRepository>()) {
      Get.put<AuthRepository>(HavenAuthRepository.live(), permanent: true);
    }
    return Get.find<AuthRepository>();
  }
}

final class SignInBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<SignInController>(
      SignInController(repository: AuthDependencies.ensureRepository()),
    );
  }
}

final class RegisterBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<RegisterController>(
      RegisterController(repository: AuthDependencies.ensureRepository()),
    );
  }
}

/// Session-ended needs no controller: it shows the one sentence it was given and
/// offers one way forward.
final class SessionEndedBindings extends Bindings {
  @override
  void dependencies() {}
}
