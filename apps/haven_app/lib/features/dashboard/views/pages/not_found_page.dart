import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../core/widgets/widgets.dart';

/// Where a navigation lands when the screen behind it is not built yet.
///
/// This is not a decorative 404: during the staged build it is the honest answer
/// to "what happens if I tap that", and it is what the app will show if a route
/// is registered before its page exists.
final class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String wanted = Get.currentRoute;
    return HavenScaffold(
      title: 'Not available yet',
      showBackendBanner: false,
      body: ListView(
        padding: const EdgeInsets.all(HavenSpacing.gutter),
        children: [
          Text(
            'This part of Haven has not been built yet.',
            style: HavenText.title,
          ),
          const SizedBox(height: HavenSpacing.md),
          Text(
            'Nothing was changed and no data was shown. If you expected to be '
            'here, use the back button — the rest of the app still works.',
            style: HavenText.body,
          ),
          const SizedBox(height: HavenSpacing.lg),
          BlockedNotice(
            requirement: 'Screen not implemented',
            missing: wanted.isEmpty ? 'no route' : wanted,
          ),
          const SizedBox(height: HavenSpacing.lg),
          HavenButton(
            label: 'Go to the start screen',
            onPressed: () => Get.offAllNamed(AppRoutes.splash),
            expand: true,
          ),
        ],
      ),
    );
  }
}
