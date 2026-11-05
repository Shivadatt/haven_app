import 'package:get/get.dart';

import '../controllers/verify_email_controller.dart';

/// Bindings for the verify email screen.
final class VerifyEmailBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VerifyEmailController>(
      () => VerifyEmailController(),
    );
  }
}
