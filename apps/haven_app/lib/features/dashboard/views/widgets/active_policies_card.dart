import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/dashboard_controller.dart';
import '../../data/dashboard_repository.dart';

/// Active policy summary card on the Parent Dashboard.
final class ActivePoliciesCard extends GetView<DashboardController> {
  const ActivePoliciesCard({required this.data, super.key});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final int count = data.activePoliciesCount;
    return SectionCard(
      title: 'Active policies',
      subtitle: count == 0
          ? 'No active policy rules configured.'
          : '$count active rule ${count == 1 ? 'version' : 'versions'} enforcing restrictions.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage limits, allowed apps, and web filtering rules are '
            'assigned per device.',
            style: HavenText.body,
          ),
          const SizedBox(height: HavenSpacing.md),
          HavenButton(
            label: 'Manage policy rules',
            primary: false,
            onPressed: controller.goToPolicies,
          ),
        ],
      ),
    );
  }
}
