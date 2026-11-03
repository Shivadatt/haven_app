import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/settings_controller.dart';
import '../../data/settings_repository.dart';

/// What Haven asks the operating system for, and why — written for the parent,
/// because a monitoring app that hides its permissions is not one a family can
/// trust (§7C of the brief).
///
/// The states shown here are the ones *this* app can observe. What a child's
/// device allows is reported by that device and read on its own screen; this
/// page never guesses it.
final class PermissionStatusPage extends GetView<SettingsController> {
  const PermissionStatusPage({super.key});

  static const _onTheChildPhone = [
    (
      'Usage access',
      'Lets Haven see which apps are on the device and how long each was used. '
          'Android asks for this once, in Settings, and your child can see it '
          'there.',
    ),
    (
      'Location, while in use',
      'Used for safe-zone arrival and departure. Haven takes it only while the '
          'Haven app is open on the device.',
    ),
    (
      'Background location',
      'Optional. Without it, location still works while the app is open; with '
          'it, safe zones can update when the app is in the background. Your '
          'child is asked for it separately.',
    ),
    (
      'Notifications',
      'Lets the device show what Haven is doing, so it is never silent on the '
          'phone it is watching.',
    ),
    (
      'Camera and microphone',
      'Only ever used during a remote session your child has agreed to. Haven '
          'does not turn either one on by itself.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Permissions Haven needs',
      body: HavenPageBody(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
          children: [
            const _ThisPhone(),
            const SizedBox(height: HavenSpacing.md),
            SectionCard(
              title: 'On your child’s phone',
              subtitle: 'The device reports these itself.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (String name, String why) in _onTheChildPhone)
                    Padding(
                      padding: const EdgeInsets.only(bottom: HavenSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: HavenText.label),
                          const SizedBox(height: HavenSpacing.xs),
                          Text(why, style: HavenText.body),
                        ],
                      ),
                    ),
                  HavenButton(
                    label: 'Open paired devices',
                    primary: false,
                    onPressed: () => Get.toNamed(AppRoutes.devices),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThisPhone extends GetView<SettingsController> {
  const _ThisPhone();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'On this phone',
      subtitle: 'Haven needs one permission here: notifications.',
      trailing: Obx(
        () => StatusChip(
          label: switch (controller.notifications.value) {
            NotificationAccess.granted => 'Allowed',
            NotificationAccess.denied => 'Not allowed',
            NotificationAccess.unavailable => 'Not in this build',
          },
          tone: switch (controller.notifications.value) {
            NotificationAccess.granted => StatusTone.good,
            NotificationAccess.denied => StatusTone.warning,
            NotificationAccess.unavailable => StatusTone.blocked,
          },
        ),
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Without it you still see every alert when you open Haven; you '
              'just are not told while the app is closed. Haven does not ask '
              'for this phone’s location, contacts or storage.',
              style: HavenText.body,
            ),
            if (controller.notificationPrompt.value != null) ...[
              const SizedBox(height: HavenSpacing.md),
              BlockedNotice.fromFailure(controller.notificationPrompt.value!),
            ],
            if (controller.message.value != null) ...[
              const SizedBox(height: HavenSpacing.sm),
              Text(controller.message.value!, style: HavenText.body),
            ],
            if (controller.canAskForNotifications) ...[
              const SizedBox(height: HavenSpacing.md),
              HavenButton(
                label: 'Allow notifications',
                onPressed: controller.askForNotifications,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
