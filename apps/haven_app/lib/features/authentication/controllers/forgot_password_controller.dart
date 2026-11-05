import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';

/// Controller for account password recovery.
///
/// In offline-first mode, email dispatch is unavailable. The controller
/// explains this constraint honestly and guides the user toward local reset.
final class ForgotPasswordController extends GetxController {
  ForgotPasswordController({
    void Function(String route, Object? arg)? goTo,
  }) : _goTo =
           goTo ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final void Function(String route, Object? arg) _goTo;

  final TextEditingController email = TextEditingController();
  final RxnString emailError = RxnString();
  final RxnString feedbackMessage = RxnString();
  final RxBool busy = false.obs;
  final RxBool isSubmitted = false.obs;

  @override
  void onClose() {
    email.dispose();
    super.onClose();
  }

  bool _validate() {
    final String? problem = validateEmail(email.text);
    emailError.value = problem;
    return problem == null;
  }

  Future<void> submit() async {
    if (busy.value) return;
    feedbackMessage.value = null;
    if (!_validate()) return;

    busy.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    busy.value = false;
    isSubmitted.value = true;
    feedbackMessage.value =
        'Haven is running in offline mode. Password reset emails cannot be '
        'dispatched without a cloud backend. For local accounts, you can '
        'update your password directly on this device.';
  }

  void goToResetPassword() {
    Get.toNamed(AppRoutes.resetPassword, arguments: email.text.trim());
  }

  void goToSignIn() {
    _goTo(AppRoutes.signIn, null);
  }
}
