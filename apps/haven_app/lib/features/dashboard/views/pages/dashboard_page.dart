import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../family/data/family_models.dart';
import '../../../family/views/widgets/people_card.dart';
import '../../controllers/dashboard_controller.dart';
import '../../data/dashboard_repository.dart';
import '../widgets/active_policies_card.dart';
import '../widgets/attention_card.dart';
import '../widgets/dashboard_devices_card.dart';
import '../widgets/demo_data_card.dart';
import '../widgets/device_records_card.dart';
import '../widgets/recent_activities_card.dart';
import '../widgets/safe_places_card.dart';

/// The parent's first screen: the family, the children in it, and what has been
/// reported lately. Everything here came from a read that happened.
final class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Haven',
      onRefresh: controller.reload,
      body: HavenPageBody(
        child: Obx(
          () => StateView<DashboardData>(
            isLoading: controller.isLoading.value,
            result: controller.data.value,
            onRetry: controller.load,
            onData: (BuildContext context, DashboardData data) =>
                _Content(data),
          ),
        ),
      ),
    );
  }
}

class _Content extends GetView<DashboardController> {
  const _Content(this.data);

  final DashboardData data;

  static String _counted(FamilyBundle bundle) {
    final int children = bundle.children.length;
    final int parents = bundle.parents.length;
    return '$children ${children == 1 ? 'child' : 'children'} and '
        '$parents ${parents == 1 ? 'parent' : 'parents'} in this family.';
  }

  @override
  Widget build(BuildContext context) {
    final FamilyBundle? family = data.family;
    if (family == null) return const _NeedsSetup();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: family.family.name,
            subtitle: _counted(family),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.isDemo) ...[
                  const StatusChip(label: 'DEMO FAMILY', tone: StatusTone.warning),
                  const SizedBox(height: HavenSpacing.sm),
                ],
                Text(
                  'Names, who is in the family and what Haven can change about '
                  'it are on one screen.',
                  style: HavenText.body,
                ),
                const SizedBox(height: HavenSpacing.md),
                HavenButton(
                  label: 'Open your family',
                  primary: false,
                  onPressed: controller.goToFamily,
                ),
              ],
            ),
          ),
          const SizedBox(height: HavenSpacing.md),
          PeopleCard(
            title: 'Your children',
            people: family.children,
            emptyLine:
                'No children are in this family yet. A child joins when their '
                'own device is paired — open Devices to see what pairing needs '
                'before that can happen.',
            onTap: controller.goToChild,
          ),
          const SizedBox(height: HavenSpacing.md),
          AttentionCard(data: data, onOpenAll: controller.goToNotifications),
          const SizedBox(height: HavenSpacing.md),
          SafePlacesCard(onOpen: controller.goToSafeZones),
          const SizedBox(height: HavenSpacing.md),
          ActivePoliciesCard(data: data),
          const SizedBox(height: HavenSpacing.md),
          RecentActivitiesCard(data: data),
          const SizedBox(height: HavenSpacing.md),
          DashboardDevicesCard(data: data),
          const SizedBox(height: HavenSpacing.md),
          DeviceRecordsCard(
            onOpenCommands: controller.goToCommands,
            onOpenPolicies: controller.goToPolicies,
            onOpenSessions: controller.goToSessions,
          ),
          const SizedBox(height: HavenSpacing.md),
          DemoDataCard(data: data),
          const SizedBox(height: HavenSpacing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Settings', style: HavenText.body),
            subtitle: Text(
              'Appearance, alerts, your account and what this build is '
              'connected to.',
              style: HavenText.caption,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: controller.goToSettings,
          ),
        ],
      ),
    );
  }
}

class _NeedsSetup extends GetView<DashboardController> {
  const _NeedsSetup();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Haven is not set up yet',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Two steps and Haven starts watching out for your family: confirm '
          'you are the parent, then name your family.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(label: 'Start setup', onPressed: controller.goToSetup),
      ],
    ),
  );
}
