import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/child_scaffold.dart';
import '../../../../shared/components/state_view.dart';
import '../../controllers/onboarding_controller.dart';
import '../../domain/onboarding_steps.dart';
import '../steps/completion_step.dart';
import '../steps/device_review_step.dart';
import '../steps/permissions_intro_step.dart';
import '../steps/profile_step.dart';
import '../steps/welcome_step.dart';

/// The 5-step shell: progress ("Step x of 5"), the current step body, and
/// back/continue below. Loading and store errors run through ChildStateView
/// with retry, exactly like a data screen.
final class OnboardingPage extends GetView<OnboardingController> {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChildScaffold(
      title: 'Setup',
      showBack: false,
      body: ChildPageBody(
        child: Obx(() {
          final loading = controller.isLoading.value;
          final error = controller.errorMessage.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: ChildSpacing.lg),
              _Progress(step: OnboardingStep.fromIndex(controller.stepIndex.value)),
              const SizedBox(height: ChildSpacing.md),
              Expanded(
                child: loading || error != null
                    ? ChildStateView<void>(
                        isLoading: loading,
                        errorMessage: error,
                        emptyMessage: '',
                        onRetry: controller.restore,
                      )
                    : _StepBody(step: OnboardingStep.fromIndex(controller.stepIndex.value)),
              ),
              _Actions(controller: controller),
              const SizedBox(height: ChildSpacing.lg),
            ],
          );
        }),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        step.progressLabel,
        style: ChildText.caption.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: ChildSpacing.xs),
      ClipRRect(
        borderRadius: BorderRadius.circular(ChildRadius.pill),
        child: LinearProgressIndicator(
          value: (step.index + 1) / OnboardingStep.count,
          minHeight: 6,
        ),
      ),
      const SizedBox(height: ChildSpacing.sm),
      Text(step.title, style: ChildText.title),
    ],
  );
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: ChildSpacing.md),
    child: switch (step) {
      OnboardingStep.welcome => const WelcomeStep(),
      OnboardingStep.childProfile => const ProfileStep(),
      OnboardingStep.deviceReview => const DeviceReviewStep(),
      OnboardingStep.permissionsIntro => const PermissionsIntroStep(),
      OnboardingStep.finish => const CompletionStep(),
    },
  );
}

class _Actions extends StatelessWidget {
  const _Actions({required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (!controller.currentStep.isLast)
        TextButton(
          onPressed: controller.stepIndex.value == 0 ? null : controller.goBack,
          child: const Text('Back'),
        ),
      const Spacer(),
      if (!controller.currentStep.isLast)
        FilledButton(
          onPressed: controller.goNext,
          child: const Text('Continue'),
        ),
    ],
  );
}
