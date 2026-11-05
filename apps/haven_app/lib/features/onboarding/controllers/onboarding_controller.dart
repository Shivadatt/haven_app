import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/storage/preferences_store.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/onboarding_models.dart';
import '../data/onboarding_repository.dart';

export '../data/onboarding_models.dart' show ChildAgeGroup, ChildAvatar, OnboardingStep;

/// Controller driving the progressive parent onboarding flow.
final class OnboardingController extends GetxController {
  OnboardingController({
    required OnboardingRepository repository,
    required AuthRepository auth,
    PreferencesStore? preferences,
    void Function(String route, Object? arg)? goTo,
  }) : _repository = repository,
       _auth = auth,
       _preferences = preferences ??
           (Get.isRegistered<PreferencesStore>()
               ? Get.find<PreferencesStore>()
               : InMemoryPreferencesStore()),
       _goTo = goTo ?? ((route, arg) => Get.offAllNamed(route, arguments: arg));

  final OnboardingRepository _repository;
  final AuthRepository _auth;
  final PreferencesStore _preferences;
  final void Function(String route, Object? arg) _goTo;

  final Rx<OnboardingStep> step = OnboardingStep.explain.obs;
  final RxBool acknowledged = false.obs;
  final RxBool busy = false.obs;
  final RxnString message = RxnString();

  final TextEditingController familyName = TextEditingController();
  final TextEditingController childName = TextEditingController();
  final Rx<ChildAgeGroup> ageGroup = ChildAgeGroup.child.obs;
  final Rx<ChildAvatar> avatar = ChildAvatar.bear.obs;

  bool get canContinue => acknowledged.value;
  bool get isBusy => busy.value;

  @override
  void onInit() {
    super.onInit();
    restoreProgress();
  }

  @override
  void onClose() {
    familyName.dispose();
    childName.dispose();
    super.onClose();
  }

  /// Resumes onboarding at the saved step and acknowledges ethics if saved.
  Future<void> restoreProgress() async {
    final String? ethics = await _preferences.read(
      PreferenceKey.onboardingEthicsAcknowledged,
    );
    if (ethics == 'true') acknowledged.value = true;

    final String? saved = await _preferences.read(PreferenceKey.onboardingStep);
    final OnboardingStep? restored = OnboardingStep.fromWire(saved);
    if (restored != null) step.value = restored;
  }

  /// Step 1: Ethics & Monitoring disclosure acknowledgment.
  Future<void> continueFromExplain() async {
    if (!acknowledged.value) {
      message.value = 'Tick the box to say you have read this.';
      return;
    }
    message.value = null;
    step.value = OnboardingStep.setup;
    await _preferences.write(
      PreferenceKey.onboardingEthicsAcknowledged,
      'true',
    );
    await _preferences.write(
      PreferenceKey.onboardingStep,
      OnboardingStep.setup.wire,
    );
  }

  /// Step 2: Family creation.
  Future<void> submitFamily() async {
    if (busy.value) return;
    message.value = null;
    final String trimmed = familyName.text.trim();
    if (trimmed.isEmpty || trimmed.length > 80) {
      message.value = trimmed.isEmpty
          ? 'Give your family a name.'
          : 'Use 80 characters or fewer.';
      return;
    }
    final Result<AuthSession?> session = await _auth.currentSession();
    if (session.valueOrNull?.userId == null) {
      message.value = session.failureOrNull?.message ??
          'Haven cannot tell who is signing up. Sign in again and try once more.';
      return;
    }
    busy.value = true;
    final Result<void> role = await _repository.claimParentRole();
    if (role.failureOrNull != null) {
      busy.value = false;
      message.value = role.failureOrNull!.message;
      return;
    }
    final Result<void> family = await _repository.createFamily(name: trimmed);
    busy.value = false;
    if (family.failureOrNull != null) {
      message.value = family.failureOrNull!.message;
      return;
    }
    await _preferences.write(
      PreferenceKey.onboardingStep,
      OnboardingStep.child.wire,
    );
    step.value = OnboardingStep.child;
  }

  /// Step 3: Child profile creation.
  Future<void> submitChild() async {
    if (busy.value) return;
    message.value = null;
    final String trimmed = childName.text.trim();
    final String? invalid = validateDisplayName(trimmed);
    if (invalid != null) {
      message.value = invalid;
      return;
    }
    busy.value = true;
    final Result<String> created = await _repository.createChild(
      name: trimmed,
      ageGroup: ageGroup.value.key,
      avatar: avatar.value.key,
    );
    busy.value = false;
    if (created.failureOrNull != null) {
      message.value = created.failureOrNull!.message;
      return;
    }
    await _preferences.write(
      PreferenceKey.onboardingStep,
      OnboardingStep.device.wire,
    );
    step.value = OnboardingStep.device;
  }

  /// Step 4: Completion and navigation to dashboard.
  Future<void> completeOnboarding() async {
    await _preferences.write(PreferenceKey.onboardingCompleted, 'true');
    _goTo(AppRoutes.dashboard, null);
  }

  /// Direct finish flow supporting programmatic completion.
  Future<void> finish() async {
    if (busy.value) return;
    message.value = null;
    final Result<AuthSession?> session = await _auth.currentSession();
    if (session.valueOrNull?.userId == null) {
      message.value = session.failureOrNull?.message ??
          'Haven cannot tell who is signing up. Sign in again and try once more.';
      return;
    }
    busy.value = true;
    final Result<void> role = await _repository.claimParentRole();
    if (role.failureOrNull != null) {
      busy.value = false;
      message.value = role.failureOrNull!.message;
      return;
    }
    final Result<void> family = await _repository.createFamily(
      name: familyName.text,
    );
    if (family.failureOrNull != null) {
      busy.value = false;
      message.value = family.failureOrNull!.message;
      return;
    }
    if (childName.text.trim().isNotEmpty) {
      await _repository.createChild(
        name: childName.text.trim(),
        ageGroup: ageGroup.value.key,
        avatar: avatar.value.key,
      );
    }
    busy.value = false;
    await _preferences.write(PreferenceKey.onboardingCompleted, 'true');
    _goTo(AppRoutes.dashboard, null);
  }
}
