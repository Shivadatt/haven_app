import 'package:get/get.dart';

import '../controllers/forgot_password_controller.dart';

/// Bindings for the forgot password workflow.
final class ForgotPasswordBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForgotPasswordController>(
      () => ForgotPasswordController(),
    );
  }
}
