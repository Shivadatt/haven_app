import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../app/routes/app_routes.dart';
import '../data/auth_repository.dart';

/// Sign-in state: which field is wrong, whether a request is in flight, and what
/// the backend said last.
///
/// The route decided after a successful sign-in is based on the profile lookup,
/// which is exactly where the provisioning gap shows up: an account can legally
/// exist with no `profiles` row, and that means "set yourself up", not "error".
final class SignInController extends GetxController {
  SignInController({
    required AuthRepository repository,
    void Function(String route, Object? arg)? goTo,
  }) : _repository = repository,
        _goTo =
           goTo ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final AuthRepository _repository;
  final void Function(String route, Object? arg) _goTo;

  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  final RxnString emailError = RxnString();
  final RxnString passwordError = RxnString();
  final RxnString formError = RxnString();
  final RxBool busy = false.obs;
  final RxBool showPassword = false.obs;

  bool get isBusy => busy.value;

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }

  /// Local rules only — the backend has its own, and its answer is what the
  /// parent eventually reads.
  bool _validate() {
    final String? emailProblem = validateEmail(email.text);
    final String? passwordProblem = validatePassword(password.text);
    emailError.value = emailProblem;
    passwordError.value = passwordProblem;
    return emailProblem == null && passwordProblem == null;
  }

  Future<void> submit() async {
    if (busy.value) return;
    formError.value = null;
    if (!_validate()) return;

    busy.value = true;
    final Result<AuthSession> signedIn = await _repository.signIn(
      email: email.text,
      password: password.text,
    );
    final HavenFailure? signInFailure = signedIn.failureOrNull;
    if (signInFailure != null) {
      busy.value = false;
      formError.value = signInFailure.message;
      return;
    }

    final AuthSession session = signedIn.valueOrNull!;
    // Clearing happens before the password leaves this screen's memory.
    password.clear();
    await _routeAfterSignIn(session.userId);
    busy.value = false;
  }

  Future<void> _routeAfterSignIn(String userId) async {
    final Result<Profile?> profile = await _repository.profileFor(userId);
    if (profile.isErr) {
      // The session is real. The dashboard reports its own read failure rather
      // than the parent being sent back to a sign-in form they just passed.
      _goTo(AppRoutes.dashboard, null);
      return;
    }
    _goTo(
      profile.valueOrNull == null ? AppRoutes.onboarding : AppRoutes.dashboard,
      null,
    );
  }

  void goRegister() => Get.toNamed(AppRoutes.register);
}
