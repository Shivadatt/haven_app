import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/reset_password_controller.dart';

/// Screen for resetting account password locally.
final class ResetPasswordPage extends GetView<ResetPasswordController> {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Reset password',
      showBack: true,
      body: HavenPageBody(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
          children: [
            if (controller.email.isNotEmpty)
              Text(
                'Resetting password for: ${controller.email}',
                style: HavenText.title,
              )
            else
              Text(
                'Choose a new password for your account.',
                style: HavenText.body,
              ),
            const SizedBox(height: HavenSpacing.lg),
            _PasswordField(
              label: 'New password',
              textController: controller.newPassword,
              errorRx: controller.passwordError,
              controller: controller,
            ),
            const SizedBox(height: HavenSpacing.md),
            _PasswordField(
              label: 'Confirm new password',
              textController: controller.confirmPassword,
              errorRx: controller.confirmError,
              controller: controller,
            ),
            const SizedBox(height: HavenSpacing.md),
            Obx(
              () => HavenButton(
                label: 'Save new password',
                expand: true,
                busy: controller.busy.value,
                onPressed: controller.submit,
              ),
            ),
            const SizedBox(height: HavenSpacing.lg),
            Obx(() {
              final String? msg = controller.statusMessage.value;
              if (msg == null) return const SizedBox.shrink();
              return SectionCard(
                title: controller.isSuccess.value ? 'Password updated' : 'Notice',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(msg, style: HavenText.body),
                    if (controller.isSuccess.value) ...[
                      const SizedBox(height: HavenSpacing.md),
                      HavenButton(
                        label: 'Sign in with new password',
                        onPressed: controller.goToSignIn,
                      ),
                    ],
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.textController,
    required this.errorRx,
    required this.controller,
  });

  final String label;
  final TextEditingController textController;
  final RxnString errorRx;
  final ResetPasswordController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final bool reveal = !controller.showPassword.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: textController,
          obscureText: reveal,
          enabled: !controller.busy.value,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: TextButton(
              onPressed: () => controller.showPassword.toggle(),
              child: Text(reveal ? 'Show' : 'Hide'),
            ),
          ),
        ),
        if (errorRx.value != null)
          Padding(
            padding: const EdgeInsets.only(left: HavenSpacing.xs),
            child: Text(errorRx.value!, style: HavenText.caption),
          ),
      ],
    );
  });
}
