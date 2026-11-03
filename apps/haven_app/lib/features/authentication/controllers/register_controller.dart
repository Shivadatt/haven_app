import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/auth_repository.dart';

/// Creates the parent account.
///
/// The identity provider is Supabase Auth; Firebase is only an external token
/// source in the ratified bridge, so nothing here mentions device UIDs. Whether
/// the staging project asks for email confirmation is not captured in the
/// evidence, so the screen reports exactly what the backend returned and adds no
/// promise of its own.
final class RegisterController extends GetxController {
  RegisterController({
    required this._repository,
    void Function(String route, Object? arg)? goTo,
  }) : _goTo =
           goTo ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final AuthRepository _repository;
  final void Function(String route, Object? arg) _goTo;

  final TextEditingController displayName = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  final RxnString nameError = RxnString();
  final RxnString emailError = RxnString();
  final RxnString passwordError = RxnString();
  final RxnString formError = RxnString();
  final RxBool busy = false.obs;
  final RxBool showPassword = false.obs;

  @override
  void onClose() {
    displayName.dispose();
    email.dispose();
    password.dispose();
    super.onClose();
  }

  bool _validate() {
    final String? name = validateDisplayName(displayName.text);
    final String? mail = validateEmail(email.text);
    final String? pass = validatePassword(password.text);
    nameError.value = name;
    emailError.value = mail;
    passwordError.value = pass;
    return name == null && mail == null && pass == null;
  }

  Future<void> submit() async {
    if (busy.value) return;
    formError.value = null;
    if (!_validate()) return;

    busy.value = true;
    final Result<AuthSession> created = await _repository.register(
      email: email.text,
      password: password.text,
      displayName: displayName.text,
    );
    final HavenFailure? failure = created.failureOrNull;
    busy.value = false;
    if (failure != null) {
      formError.value = failure.message;
      return;
    }

    password.clear();
    // A new account has no `profiles` row: onboarding is the next step, and it
    // is the provisioning path the evidence actually leaves open.
    _goTo(AppRoutes.onboarding, null);
  }

  void goSignIn() => Get.back();
}
