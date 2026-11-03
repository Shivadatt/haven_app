import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/haven_colors.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/sign_in_controller.dart';

/// Email and password only. There is no "sign in with Google" or "sign in with
/// Firebase" button: the Firebase bridge is a server-side exchange that is not
/// approved or loaded yet, so offering it would be a fake control.
final class SignInPage extends GetView<SignInController> {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Sign in',
      showBack: false,
      body: HavenPageBody(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
          children: [
            Text(
              'Your family’s devices, screens and alerts in one place.',
              style: HavenText.body.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: HavenSpacing.lg),
            _EmailField(controller: controller),
            const SizedBox(height: HavenSpacing.md),
            _PasswordField(controller: controller),
            const SizedBox(height: HavenSpacing.md),
            _FormError(controller: controller),
            const SizedBox(height: HavenSpacing.sm),
            Obx(
              () => HavenButton(
                label: 'Sign in',
                expand: true,
                busy: controller.busy.value,
                onPressed: controller.submit,
              ),
            ),
            const SizedBox(height: HavenSpacing.md),
            _RegisterLink(),
          ],
        ),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});

  final SignInController controller;

  @override
  Widget build(BuildContext context) => Obx(
    () => HavenField(
      label: 'Email',
      controller: controller.email,
      keyboardType: TextInputType.emailAddress,
      autofillHint: AutofillHints.email,
      helper: controller.emailError.value,
      enabled: !controller.isBusy,
    ),
  );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.controller});

  final SignInController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final bool reveal = !controller.showPassword.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller.password,
          obscureText: reveal,
          enabled: !controller.isBusy,
          autofillHints: const [AutofillHints.password],
          style: HavenText.body,
          decoration: InputDecoration(
            labelText: 'Password',
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

class _FormError extends StatelessWidget {
  const _FormError({required this.controller});

  final SignInController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final String? error = controller.formError.value;
    if (error == null) return const SizedBox.shrink();
    return Text(error, style: HavenText.body.copyWith(color: HavenColors.bad));
  });
}

class _RegisterLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('New to Haven?'),
      TextButton(
        onPressed: () => Get.toNamed(AppRoutes.register),
        child: const Text('Create an account'),
      ),
    ],
  );
}
