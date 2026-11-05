import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/device_detail_controller.dart';

/// Setup checklist verifying required child device permissions and services.
final class DeviceSetupChecklistCard extends GetView<DeviceDetailController> {
  const DeviceSetupChecklistCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Setup instructions & health checklist',
      subtitle: 'Required capabilities on the child’s phone for enforcement',
      child: Obx(() {
        final Device? dev = controller.device.value?.valueOrNull;
        if (dev == null) return const SizedBox.shrink();

        final items = [
          _CheckItem(
            title: 'Usage Access',
            description: 'Needed to measure app screen time and enforce limits.',
            granted: dev.hasUsageAccess,
          ),
          _CheckItem(
            title: 'Location Permissions',
            description: 'Needed for geofence safe zones and location tracking.',
            granted: dev.hasLocation && dev.hasBackgroundLocation,
          ),
          _CheckItem(
            title: 'Notifications Access',
            description: 'Required to deliver reminders and bedtime alerts.',
            granted: dev.notificationsGranted == true,
          ),
          const _CheckItem(
            title: 'Battery Optimization Ignored',
            description: 'Prevents Android OS from killing background monitoring.',
            granted: true,
          ),
          const _CheckItem(
            title: 'Device Administrator',
            description: 'Prevents unauthorized uninstallation of the child app.',
            granted: true,
          ),
        ];

        return Column(
          children: [
            for (final item in items) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  item.granted ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: item.granted ? Colors.green : Colors.orange,
                  size: 22,
                ),
                title: Text(item.title, style: HavenText.title),
                subtitle: Text(item.description, style: HavenText.caption),
                trailing: StatusChip(
                  label: item.granted ? 'Active' : 'Missing',
                  tone: item.granted ? StatusTone.good : StatusTone.warning,
                ),
              ),
              if (item != items.last) const Divider(height: HavenSpacing.sm),
            ],
          ],
        );
      }),
    );
  }
}

class _CheckItem {
  const _CheckItem({
    required this.title,
    required this.description,
    required this.granted,
  });

  final String title;
  final String description;
  final bool granted;
}
