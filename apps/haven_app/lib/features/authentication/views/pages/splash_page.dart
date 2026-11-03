import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../core/constants/haven_config.dart';
import '../../../../core/widgets/widgets.dart';
import '../../controllers/splash_controller.dart';

/// First screen: connects, decides where to go, and says what it found.
///
/// Nothing is pre-filled while it waits — no skeleton dashboard, no sample
/// child. A parent who opens this build before staging is configured sees the
/// connection state instead of a mock-up.
final class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final HavenConfig config = Get.find<HavenConfig>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(HavenSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Wordmark(),
                  const SizedBox(height: HavenSpacing.xl),
                  _Stage(controller: controller, config: config),
                  const SizedBox(height: HavenSpacing.xl),
                  Text(
                    config.isStaging
                        ? 'Staging build'
                        : 'This build is not marked staging — do not use it',
                    textAlign: TextAlign.center,
                    style: HavenText.caption,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _Stage extends StatelessWidget {
  const _Stage({required this.controller, required this.config});

  final SplashController controller;
  final HavenConfig config;

  @override
  Widget build(BuildContext context) => Obx(
    () => switch (controller.stage.value) {
      SplashStage.connecting => const Padding(
        padding: EdgeInsets.symmetric(vertical: HavenSpacing.md),
        child: Column(
          children: [
            LinearProgressIndicator(),
            SizedBox(height: HavenSpacing.md),
            Text('Connecting…', style: HavenText.body),
          ],
        ),
      ),
      SplashStage.stalled => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlockedNotice(
            requirement: controller.message ?? config.status.message,
          ),
          const SizedBox(height: HavenSpacing.md),
          HavenButton(label: 'Try again', onPressed: controller.start),
        ],
      ),
      SplashStage.away => const SizedBox.shrink(),
    },
  );
}

final class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('Haven', style: HavenText.largeTitle),
      const SizedBox(height: HavenSpacing.xs),
      Text(
        'Calm supervision for a child\'s device',
        textAlign: TextAlign.center,
        style: HavenText.body.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
