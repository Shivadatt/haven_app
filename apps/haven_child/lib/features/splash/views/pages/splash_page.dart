import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/child_scaffold.dart';
import '../../controllers/splash_controller.dart';

/// The real boot screen (brief §4 F): a loading state while storage opens,
/// and on failure an honest message with a retry — plus, ONLY when the stored
/// document is genuinely corrupt, an explicit developer reset. Nothing here
/// auto-clears a family's data.
final class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChildScaffold(
      title: 'Haven Child',
      showBack: false,
      body: ChildPageBody(child: _SplashBody()),
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SplashController>();
    return Obx(() {
      if (controller.isBooting.value) return const _Booting();
      final error = controller.errorMessage.value;
      if (error == null) {
        // Boot SUCCEEDED — the route swap is what leaves this screen, so the
        // honest frame while that lands (or animates) is still the booting
        // one. Never render a fake "could not start" over a good boot.
        return const _Booting();
      }
      return _BootFailure(
        controller: controller,
        message: error,
      );
    });
  }
}

class _Booting extends StatelessWidget {
  const _Booting();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: ChildSpacing.xl),
      Text('Haven Child', style: ChildText.largeTitle),
      const SizedBox(height: ChildSpacing.sm),
      Text(
        'Starting Haven Child…',
        style: ChildText.caption.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const Spacer(),
      const Center(child: CircularProgressIndicator()),
      const SizedBox(height: ChildSpacing.xl),
    ],
  );
}

class _BootFailure extends StatelessWidget {
  const _BootFailure({required this.controller, required this.message});

  final SplashController controller;
  final String message;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: ChildSpacing.xl),
        Text('The app could not start', style: ChildText.title),
        const SizedBox(height: ChildSpacing.md),
        Text(message, style: ChildText.body),
        const SizedBox(height: ChildSpacing.md),
        OutlinedButton(
          onPressed: controller.boot,
          child: const Text('Try again'),
        ),
        Obx(() {
          if (!controller.storageIsCorrupt.value) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: ChildSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The stored data is damaged and has deliberately NOT been '
                  'reset. A developer can replace it with an empty start — '
                  'this erases everything on this device.',
                  style: ChildText.caption,
                ),
                const SizedBox(height: ChildSpacing.sm),
                OutlinedButton(
                  onPressed: controller.isResetting.value
                      ? null
                      : controller.resetAndReboot,
                  child: const Text('Reset local data (developer)'),
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );
}
