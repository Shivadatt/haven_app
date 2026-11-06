import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../app/routes/child_routes.dart';
import '../../../core/device/device_information.dart';
import '../../../core/storage/onboarding_state_store.dart';
import '../domain/onboarding_flow.dart';
import '../domain/onboarding_steps.dart';
import '../services/onboarding_completion.dart';

/// Drives the five-step onboarding: restores the persisted draft on init,
/// re-persists step + fields on every navigation (brief §4 C "resume from
/// persisted step+draft"), and finishes through [OnboardingCompletion] behind
/// an in-flight flag so a double tap cannot double-create.
///
/// Constructor injection, `onInit` load, `onClose` dispose, `isClosed`
/// guards after every await — the parent's
/// `PairingSimulationController` shape, deliberately.
final class OnboardingController extends GetxController {
  OnboardingController({
    required this.drafts,
    required this.completion,
    required this.device,
    required this.push,
    required this.finishRoute,
  });

  final OnboardingStateStore drafts;
  final OnboardingCompletion completion;
  final DeviceInformation device;

  /// Detail screens (device, permissions) open ON TOP of onboarding — the
  /// child can always come back; `pop` returns to the same step.
  final void Function(String route) push;
  final void Function(String route) finishRoute;

  final TextEditingController nameController = TextEditingController();
  final RxInt stepIndex = 0.obs;
  final RxString ageBracket = ''.obs;
  final RxString avatar = ''.obs;
  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    restore();
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  OnboardingStep get currentStep => OnboardingStep.fromIndex(stepIndex.value);

  DeviceFacts get deviceFacts => device.read();

  Future<void> restore() async {
    isLoading.value = true;
    errorMessage.value = null;
    final saved = await drafts.read();
    if (isClosed) return;
    if (saved case Err<OnboardingDraft?>()) {
      errorMessage.value = saved.failureOrNull!.message;
      isLoading.value = false;
      return;
    }
    final draft = saved.valueOrNull;
    if (draft != null) {
      nameController.text = draft.displayName ?? '';
      ageBracket.value = draft.ageBracket ?? '';
      avatar.value = draft.avatar ?? '';
      stepIndex.value = OnboardingFlow.clampIndex(draft.stepIndex);
    }
    isLoading.value = false;
  }

  Future<void> goNext() async {
    final blocker = OnboardingFlow.blockerFor(
      currentStep,
      displayName: nameController.text,
      ageBracket: ageBracket.value,
    );
    if (blocker != null) {
      errorMessage.value = blocker;
      return;
    }
    if (currentStep.isLast) return; // the finish step acts via finish()
    errorMessage.value = null;
    final next = stepIndex.value + 1;
    await _persist(next);
    if (isClosed) return;
    stepIndex.value = next;
  }

  Future<void> goBack() async {
    if (stepIndex.value == OnboardingStep.welcome.index) return;
    errorMessage.value = null;
    final previous = stepIndex.value - 1;
    await _persist(previous);
    if (isClosed) return;
    stepIndex.value = previous;
  }

  Future<void> _persist(int index) async {
    final saved = await drafts.save(
      OnboardingDraft(
        stepIndex: index,
        displayName: _trimmedOrNull(nameController.text),
        ageBracket: _trimmedOrNull(ageBracket.value),
        avatar: _trimmedOrNull(avatar.value),
      ),
    );
    if (isClosed) return;
    if (saved.isErr) errorMessage.value = saved.failureOrNull!.message;
  }

  void openDeviceDetails() => push(ChildRoutes.device);

  void openPermissionExplanations() => push(ChildRoutes.permissions);

  Future<void> finish() async {
    if (isSubmitting.value) return; // in-flight guard: one submit at a time
    final blocker = OnboardingFlow.profileProblem(
      displayName: nameController.text,
      ageBracket: ageBracket.value,
    );
    if (blocker != null) {
      errorMessage.value = '$blocker Back to the "About you" step to fix it.';
      stepIndex.value = OnboardingStep.childProfile.index;
      return;
    }
    errorMessage.value = null;
    isSubmitting.value = true;

    final done = await completion(
      displayName: nameController.text,
      ageBracket: ageBracket.value,
      avatar: _trimmedOrNull(avatar.value),
    );
    if (isClosed) return;
    isSubmitting.value = false;

    if (done case Err<Profile>()) {
      errorMessage.value = done.failureOrNull!.message;
      return;
    }
    finishRoute(ChildRoutes.profile);
  }

  static String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
