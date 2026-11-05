import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/forgot_password_controller.dart';

/// Password recovery screen with offline mode explanation.
final class ForgotPasswordPage extends GetView<ForgotPasswordController> {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Recover password',
      showBack: true,
      body: HavenPageBody(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
          children: [
            Text(
              'Enter the email address registered with your Haven account.',
              style: HavenText.body.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: HavenSpacing.lg),
            Obx(
              () => HavenField(
                label: 'Email',
                controller: controller.email,
                keyboardType: TextInputType.emailAddress,
                autofillHint: AutofillHints.email,
                helper: controller.emailError.value,
                enabled: !controller.busy.value,
              ),
            ),
            const SizedBox(height: HavenSpacing.md),
            Obx(
              () => HavenButton(
                label: 'Request password recovery',
                expand: true,
                busy: controller.busy.value,
                onPressed: controller.submit,
              ),
            ),
            const SizedBox(height: HavenSpacing.lg),
            Obx(() {
              final String? message = controller.feedbackMessage.value;
              if (message == null) return const SizedBox.shrink();
              return SectionCard(
                title: 'Offline recovery note',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message, style: HavenText.body),
                    const SizedBox(height: HavenSpacing.md),
                    HavenButton(
                      label: 'Reset password locally',
                      primary: false,
                      onPressed: controller.goToResetPassword,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: HavenSpacing.md),
            Center(
              child: TextButton(
                onPressed: controller.goToSignIn,
                child: const Text('Back to sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
