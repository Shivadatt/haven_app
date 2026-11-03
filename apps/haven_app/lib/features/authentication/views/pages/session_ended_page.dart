import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';

/// Shown when the session goes away: expired, signed out elsewhere, or rejected.
///
/// The route argument is the reason the app actually observed — never a guess.
/// Missing or blank is stated as unknown instead of being padded with an
/// invented cause.
final class SessionEndedPage extends StatelessWidget {
  const SessionEndedPage({super.key});

  static const _fallback = "Haven lost the session and doesn't know why.";

  @override
  Widget build(BuildContext context) {
    final Object? arg = Get.arguments;
    final String reason = (arg is String && arg.trim().isNotEmpty)
        ? arg.trim()
        : _fallback;

    return HavenScaffold(
      title: 'Signed out',
      showBack: false,
      body: HavenPageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: HavenSpacing.xl),
            Icon(
              Icons.lock_open_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: HavenSpacing.lg),
            Text('Your sign-in is no longer active.', style: HavenText.title),
            const SizedBox(height: HavenSpacing.sm),
            Text(reason, style: HavenText.body),
            const SizedBox(height: HavenSpacing.sm),
            Text(
              'Signing in again brings you back to the same screens.',
              style: HavenText.body.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: HavenSpacing.xl),
            HavenButton(
              label: 'Sign in again',
              expand: true,
              onPressed: () => Get.offAllNamed(AppRoutes.signIn),
            ),
          ],
        ),
      ),
    );
  }
}
