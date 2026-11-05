import 'package:flutter/material.dart';
import '../../../../app/theme/haven_colors.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../shared/components/section_card.dart';
import '../../controllers/dashboard_controller.dart';

class DashboardQuickActionsCard extends StatelessWidget {
  const DashboardQuickActionsCard({super.key, required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.timer_outlined,
        label: 'App Limits',
        onTap: controller.goToAppLimits,
      ),
      _ActionItem(
        icon: Icons.apps_rounded,
        label: 'App Rules',
        onTap: controller.goToAppRules,
      ),
      _ActionItem(
        icon: Icons.public_rounded,
        label: 'Web Filter',
        onTap: controller.goToWebFilter,
      ),
      _ActionItem(
        icon: Icons.schedule_rounded,
        label: 'Schedules',
        onTap: controller.goToSchedules,
      ),
      _ActionItem(
        icon: Icons.location_on_outlined,
        label: 'Location Map',
        onTap: controller.goToLocation,
      ),
      _ActionItem(
        icon: Icons.assignment_turned_in_outlined,
        label: 'Approvals',
        onTap: controller.goToApprovals,
      ),
      _ActionItem(
        icon: Icons.hourglass_top_rounded,
        label: 'Extensions',
        onTap: controller.goToExtensionRequests,
      ),
      _ActionItem(
        icon: Icons.family_restroom_rounded,
        label: 'Profiles',
        onTap: controller.goToFamily,
      ),
      _ActionItem(
        icon: Icons.help_outline_rounded,
        label: 'Help Centre',
        onTap: controller.goToHelp,
      ),
    ];

    return SectionCard(
      title: 'Quick Controls',
      subtitle: 'Shortcuts to parental policies, safety & support',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 500 ? 4 : 3;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: HavenSpacing.sm,
              crossAxisSpacing: HavenSpacing.sm,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final item = actions[index];
              return InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: HavenSpacing.sm,
                    horizontal: HavenSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: HavenColors.surface,
                    border: Border.all(color: HavenColors.outline.withAlpha(80)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: HavenColors.primary, size: 24),
                      const SizedBox(height: HavenSpacing.xs),
                      Text(
                        item.label,
                        style: HavenText.caption,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
