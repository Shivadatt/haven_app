import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/dashboard_controller.dart';
import '../../data/dashboard_repository.dart';

/// Card providing deterministic demo data management for local offline evaluation.
final class DemoDataCard extends GetView<DashboardController> {
  const DemoDataCard({required this.data, super.key});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Demo Data Suite',
      subtitle: data.isDemo
          ? 'Demo dataset is active. All demo records are marked with DEMO badge.'
          : 'Generate deterministic sample family records for offline QA.',
      child: Obx(() {
        if (controller.isDemoBusy.value) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: HavenSpacing.sm),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.isDemo) ...[
              const StatusChip(label: 'DEMO ACTIVE', tone: StatusTone.warning),
              const SizedBox(height: HavenSpacing.sm),
              Text(
                'Clearing demo data removes all records with is_demo: true and '
                'leaves your real user records completely untouched.',
                style: HavenText.caption,
              ),
              const SizedBox(height: HavenSpacing.md),
              HavenButton(
                label: 'Remove demo data',
                primary: false,
                onPressed: controller.removeDemoData,
              ),
            ] else ...[
              Text(
                'Load a simulated family with child profile, registered Pixel 8 '
                'phone, safe zones, policy rules, and recent activity logs.',
                style: HavenText.body,
              ),
              const SizedBox(height: HavenSpacing.md),
              HavenButton(
                label: 'Load deterministic demo data',
                primary: true,
                onPressed: controller.loadDemoData,
              ),
            ],
          ],
        );
      }),
    );
  }
}
