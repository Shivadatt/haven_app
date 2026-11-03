import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/onboarding_repository.dart';

/// First-run setup, in the order the decisions actually have to happen.
///
/// `explain` is a gate, not a scroll: the parent cannot continue without
/// saying they have read what monitoring does. `setup` writes the two things
/// the approved backend accepts — the account's own role and the family name.
enum OnboardingStep { explain, setup }

final class OnboardingController extends GetxController {
  OnboardingController({
    required this._repository,
    required this._auth,
    void Function(String route, Object? arg)? goTo,
  }) : _goTo =
           goTo ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final OnboardingRepository _repository;
  final AuthRepository _auth;
  final void Function(String route, Object? arg) _goTo;

  final Rx<OnboardingStep> step = OnboardingStep.explain.obs;

  /// Explicit, recorded in this session: the parent pressed the button. Whether
  /// a consent *may be stored at all* is blocked — the captured schema has no
  /// consent table or column, so the screen says so instead of implying a record.
  final RxBool acknowledged = false.obs;
  final RxBool busy = false.obs;
  final RxnString message = RxnString();

  final TextEditingController familyName = TextEditingController();

  bool get canContinue => acknowledged.value;
  bool get isBusy => busy.value;

  @override
  void onClose() {
    familyName.dispose();
    super.onClose();
  }

  /// The one action on the explanation step. Staying put with a reason is more
  /// useful to a parent than a greyed-out button that says nothing.
  void continueFromExplain() {
    if (!acknowledged.value) {
      message.value = 'Tick the box to say you have read this.';
      return;
    }
    message.value = null;
    step.value = OnboardingStep.setup;
  }

  /// Claims the parent role, then creates the family. Stops at the first answer
  /// the backend refuses, because a half-finished setup shown as complete is
  /// worse than a visible stop.
  Future<void> finish() async {
    if (busy.value) return;
    message.value = null;

    final Result<AuthSession?> session = await _auth.currentSession();
    final String? userId = session.valueOrNull?.userId;
    if (userId == null) {
      message.value =
          session.failureOrNull?.message ??
          'Haven cannot tell who is signing up. Sign in again and try once more.';
      return;
    }

    busy.value = true;
    final Result<void> role = await _repository.claimParentRole();
    final HavenFailure? roleFailure = role.failureOrNull;
    if (roleFailure != null) {
      busy.value = false;
      message.value = roleFailure.message;
      return;
    }

    final Result<void> family = await _repository.createFamily(
      name: familyName.text,
    );
    final HavenFailure? familyFailure = family.failureOrNull;
    busy.value = false;
    if (familyFailure != null) {
      message.value = familyFailure.message;
      return;
    }

    _goTo(AppRoutes.dashboard, null);
  }
}
