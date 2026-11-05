import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../controllers/settings_controller.dart';

/// Local notification preferences toggles.
final class NotificationPreferencesCard extends GetView<SettingsController> {
  const NotificationPreferencesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Notification Preferences',
      subtitle: 'Local notification toggles for device events',
      child: Obx(() {
        final prefs = controller.notificationPrefs.value;
        return Column(
          children: [
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Daily Screen Time Alerts'),
              subtitle: const Text('Notify when child reaches screen time limits'),
              value: prefs.screenTimeAlerts,
              onChanged: (val) => controller.updateNotificationPref(screenTime: val),
            ),
            const Divider(height: HavenSpacing.xs),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Bedtime Reminders'),
              subtitle: const Text('15-minute advance notice before downtime'),
              value: prefs.bedtimeAlerts,
              onChanged: (val) => controller.updateNotificationPref(bedtime: val),
            ),
            const Divider(height: HavenSpacing.xs),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Safe Zone Transition Alerts'),
              subtitle: const Text('Arrivals and departures from configured places'),
              value: prefs.safeZoneAlerts,
              onChanged: (val) => controller.updateNotificationPref(safeZones: val),
            ),
            const Divider(height: HavenSpacing.xs),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('App Installation Alerts'),
              subtitle: const Text('When child installs or attempts to open blocked apps'),
              value: prefs.appInstallAlerts,
              onChanged: (val) => controller.updateNotificationPref(appInstalls: val),
            ),
          ],
        );
      }),
    );
  }
}
