import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';

/// Password reset controller for updating credentials.
///
/// Handles local password updating in offline mode and matching validation.
final class ResetPasswordController extends GetxController {
  ResetPasswordController({
    String? emailHint,
    UserAuth Function()? auth,
    SecretVault Function()? vault,
    void Function(String route, Object? arg)? goTo,
  }) : email = emailHint ?? (Get.arguments is String ? Get.arguments as String : ''),
       _auth = auth ?? (() => HavenBackend.auth),
       _vault = vault ?? (() => Get.find<SecretVault>()),
       _goTo = goTo ?? ((String route, Object? arg) => Get.offAllNamed(route, arguments: arg));

  final String email;
  final UserAuth Function() _auth;
  final SecretVault Function() _vault;
  final void Function(String route, Object? arg) _goTo;

  final TextEditingController newPassword = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  final RxnString passwordError = RxnString();
  final RxnString confirmError = RxnString();
  final RxnString statusMessage = RxnString();
  final RxBool isSuccess = false.obs;
  final RxBool busy = false.obs;
  final RxBool showPassword = false.obs;

  @override
  void onClose() {
    newPassword.dispose();
    confirmPassword.dispose();
    super.onClose();
  }

  bool _validate() {
    final String? passErr = validatePassword(newPassword.text);
    passwordError.value = passErr;
    if (confirmPassword.text != newPassword.text) {
      confirmError.value = 'Passwords do not match.';
      return false;
    }
    confirmError.value = null;
    return passErr == null;
  }

  Future<void> submit() async {
    if (busy.value) return;
    statusMessage.value = null;
    if (!_validate()) return;

    busy.value = true;
    final Result<AuthSession?> sessionRes = await _auth().currentSession();
    final String targetEmail = (sessionRes.valueOrNull?.email ?? email).trim().toLowerCase();

    if (targetEmail.isEmpty) {
      busy.value = false;
      statusMessage.value =
          'No local account email specified. Please start from Forgot Password or Sign In.';
      return;
    }

    final SecretVault v = _vault();
    if (!v.available) {
      busy.value = false;
      statusMessage.value = 'This device keystore is unavailable for password storage.';
      return;
    }

    final bool ok = await v.write('local_auth.$targetEmail', newPassword.text);
    busy.value = false;
    if (ok) {
      isSuccess.value = true;
      statusMessage.value =
          'Local password updated successfully for $targetEmail. You can now sign in.';
    } else {
      statusMessage.value = 'Failed to update local password storage.';
    }
  }

  void goToSignIn() => _goTo(AppRoutes.signIn, null);
}
