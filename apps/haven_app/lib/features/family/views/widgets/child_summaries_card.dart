import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_text.dart';
import '../../controllers/child_profile_controller.dart';

/// Summaries for configured policies, safe zones, and usage activity.
final class ChildSummariesCard extends GetView<ChildProfileController> {
  const ChildSummariesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Protections & activity',
      subtitle: 'Configured policies, geofences, and screen time',
      child: Obx(
        () => Column(
          children: [
            _SummaryTile(
              icon: Icons.shield_outlined,
              title: 'Configured policies',
              value: '${controller.policiesCount.value} active',
              onTap: controller.goToPolicies,
            ),
            const Divider(),
            _SummaryTile(
              icon: Icons.place_outlined,
              title: 'Safe zones',
              value: '${controller.safeZonesCount.value} zones monitored',
              onTap: controller.goToSafeZones,
            ),
            const Divider(),
            _SummaryTile(
              icon: Icons.schedule_outlined,
              title: 'Today’s screen time',
              value: '${controller.dailyUsageMinutes.value} minutes logged',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, size: 24),
    title: Text(title, style: HavenText.title),
    subtitle: Text(value, style: HavenText.caption),
    trailing: onTap != null ? const Icon(Icons.chevron_right, size: 20) : null,
    onTap: onTap,
  );
}
