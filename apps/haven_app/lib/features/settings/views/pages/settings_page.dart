import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/settings_controller.dart';
import '../../data/settings_repository.dart';

/// Appearance, alerts, and the way to the rest of the settings screens.
final class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Settings',
      body: HavenPageBody(
        child: Obx(
          () => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: HavenSpacing.lg,
                  ),
                  children: const [_Appearance(), _Alerts(), _AlsoHere()],
                ),
        ),
      ),
    );
  }
}

class _Appearance extends GetView<SettingsController> {
  const _Appearance();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Appearance',
    subtitle: 'How Haven looks on this phone.',
    child: Obx(
      () => Wrap(
        spacing: HavenSpacing.sm,
        runSpacing: HavenSpacing.sm,
        children: [
          for (final ThemeChoice choice in ThemeChoice.values)
            ChoiceChip(
              label: Text(choice.label),
              selected: controller.theme.value == choice,
              onSelected: (_) => controller.chooseTheme(choice),
            ),
        ],
      ),
    ),
  );
}

class _Alerts extends GetView<SettingsController> {
  const _Alerts();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Alerts on this phone',
      subtitle:
          'Safe-zone arrivals and departures, and device alerts, only reach '
          'this phone if it allows notifications.',
      trailing: Obx(
        () => StatusChip(
          label: switch (controller.notifications.value) {
            NotificationAccess.granted => 'On',
            NotificationAccess.denied => 'Off',
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
            if (controller.notificationPrompt.value != null)
              BlockedNotice.fromFailure(controller.notificationPrompt.value!),
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

class _AlsoHere extends StatelessWidget {
  const _AlsoHere();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Also here',
    child: Column(
      children: [
        _row(context, 'Your account', AppRoutes.account),
        _row(context, 'Permissions Haven needs', AppRoutes.permissionStatus),
        _row(context, 'About Haven', AppRoutes.about),
      ],
    ),
  );

  static Widget _row(BuildContext context, String label, String route) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: HavenText.body),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Get.toNamed(route),
      );
}
