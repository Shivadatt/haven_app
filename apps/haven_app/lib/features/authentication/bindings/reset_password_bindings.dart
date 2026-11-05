import 'package:get/get.dart';

import '../controllers/reset_password_controller.dart';

/// Bindings for the reset password workflow.
final class ResetPasswordBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ResetPasswordController>(
      () => ResetPasswordController(),
    );
  }
}
