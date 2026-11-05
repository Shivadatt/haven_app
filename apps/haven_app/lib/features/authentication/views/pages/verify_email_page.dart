import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/verify_email_controller.dart';

/// Screen explaining email verification in offline mode.
final class VerifyEmailPage extends GetView<VerifyEmailController> {
  const VerifyEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Verify email',
      showBack: true,
      body: HavenPageBody(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
          children: [
            SectionCard(
              title: 'Account status',
              child: Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'Account email',
                      value: controller.userEmail.value ?? 'No email on file',
                    ),
                    const SizedBox(height: HavenSpacing.xs),
                    _InfoRow(
                      label: 'Role',
                      value: controller.userRole.value.capitalizeFirst ?? 'Parent',
                    ),
                    const SizedBox(height: HavenSpacing.xs),
                    _InfoRow(
                      label: 'Verification state',
                      value: controller.accountStatus.value,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: HavenSpacing.md),
            SectionCard(
              title: 'Backend explanation',
              subtitle: 'Why email confirmation is deferred in this build',
              child: Text(
                'Haven currently runs entirely in local offline-first mode on '
                'this device. Outbound email dispatch requires an approved '
                'cloud backend and SMTP relay, which is scheduled for a future '
                'deployment phase. Your local account remains fully functional.',
                style: HavenText.body,
              ),
            ),
            const SizedBox(height: HavenSpacing.md),
            Obx(
              () => HavenButton(
                label: 'Resend verification email',
                primary: false,
                busy: controller.busy.value,
                onPressed: controller.resendVerification,
              ),
            ),
            const SizedBox(height: HavenSpacing.md),
            Obx(() {
              final String? feedback = controller.resendFeedback.value;
              if (feedback == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: HavenSpacing.md),
                child: SectionCard(
                  title: 'Resend response',
                  child: Text(feedback, style: HavenText.body),
                ),
              );
            }),
            HavenButton(
              label: 'Continue to Dashboard',
              onPressed: controller.continueToDashboard,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: HavenText.caption),
      const SizedBox(width: HavenSpacing.sm),
      Flexible(
        child: Text(
          value,
          style: HavenText.body,
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
