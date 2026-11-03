import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_colors.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/register_controller.dart';

/// The parent's own account. No child is created here: children are added once
/// the family exists, which is onboarding's job.
final class RegisterPage extends GetView<RegisterController> {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Create an account',
      body: HavenPageBody(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
          children: [
            Obx(
              () => HavenField(
                label: 'Your name',
                controller: controller.displayName,
                maxLength: 60,
                autofillHint: AutofillHints.name,
                helper: controller.nameError.value,
                enabled: !controller.busy.value,
              ),
            ),
            const SizedBox(height: HavenSpacing.md),
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
            _PasswordEntry(controller: controller),
            const SizedBox(height: HavenSpacing.md),
            Obx(() {
              final String? error = controller.formError.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error != null) ...[
                    Text(
                      error,
                      style: HavenText.body.copyWith(color: HavenColors.bad),
                    ),
                    const SizedBox(height: HavenSpacing.sm),
                  ],
                  HavenButton(
                    label: 'Create account',
                    expand: true,
                    busy: controller.busy.value,
                    onPressed: controller.submit,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PasswordEntry extends StatelessWidget {
  const _PasswordEntry({required this.controller});

  final RegisterController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final bool reveal = !controller.showPassword.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller.password,
          obscureText: reveal,
          enabled: !controller.busy.value,
          style: HavenText.body,
          decoration: InputDecoration(
            labelText: 'Password',
            helperText: 'At least 8 characters',
            counterText: '',
            suffixIcon: TextButton(
              onPressed: () => controller.showPassword.toggle(),
              child: Text(reveal ? 'Show' : 'Hide'),
            ),
          ),
        ),
        if (controller.passwordError.value != null)
          Padding(
            padding: const EdgeInsets.only(left: HavenSpacing.xs),
            child: Text(
              controller.passwordError.value!,
              style: HavenText.caption,
            ),
          ),
      ],
    );
  });
}
