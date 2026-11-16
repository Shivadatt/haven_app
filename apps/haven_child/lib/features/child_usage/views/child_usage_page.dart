import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/child_colors.dart';
import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/child_scaffold.dart';
import '../controllers/child_usage_controller.dart';
import 'widgets/app_usage_list_card.dart';
import 'widgets/daily_screen_time_card.dart';
import 'widgets/usage_access_explainer_card.dart';
import 'widgets/usage_permission_denied_card.dart';

/// Main screen displaying child device daily usage and screen time.
final class ChildUsagePage extends GetView<ChildUsageController> {
  const ChildUsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChildScaffold(
      title: 'Usage & Screen Time',
      actions: [
        IconButton(
          tooltip: 'Refresh usage data',
          icon: const Icon(Icons.refresh),
          onPressed: () => controller.refreshUsage(),
        ),
      ],
      body: ChildPageBody(
        child: RefreshIndicator(
          onRefresh: controller.refreshUsage,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: ChildSpacing.md),
            child: Obx(() => _buildContent(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        switch (controller.status.value) {
          ChildUsageStatus.initial || ChildUsageStatus.loading => const _LoadingView(),
          ChildUsageStatus.permissionRequired => UsagePermissionDeniedCard(
              onOpenSettings: controller.openUsageSettings,
              isOpeningSettings: controller.isBusy.value,
              errorMessage: controller.errorMessage.value,
            ),
          ChildUsageStatus.unsupported => const _UnsupportedView(),
          ChildUsageStatus.error => _ErrorView(
              message: controller.errorMessage.value,
              onRetry: controller.refreshUsage,
            ),
          ChildUsageStatus.empty ||
          ChildUsageStatus.delayed ||
          ChildUsageStatus.loaded =>
            _UsageContentView(controller: controller),
        },
        if (controller.status.value != ChildUsageStatus.initial &&
            controller.status.value != ChildUsageStatus.loading) ...[
          const SizedBox(height: ChildSpacing.md),
          const UsageAccessExplainerCard(),
        ],
      ],
    );
  }
}

final class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: ChildSpacing.xl),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: ChildSpacing.md),
            Text('Loading usage data...', style: ChildText.body),
          ],
        ),
      ),
    );
  }
}

final class _UnsupportedView extends StatelessWidget {
  const _UnsupportedView();

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(80));
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChildRadius.md),
        side: borderSide,
      ),
      child: const Padding(
        padding: EdgeInsets.all(ChildSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: ChildColors.blocked, size: 22),
                SizedBox(width: ChildSpacing.sm),
                Text('Platform Not Supported', style: ChildText.headline),
              ],
            ),
            SizedBox(height: ChildSpacing.sm),
            Text(
              'Usage Access statistics are only available on Android devices '
              '(API level 21 and above). This platform or environment does not '
              'support Android UsageStatsManager.',
              style: ChildText.body,
            ),
          ],
        ),
      ),
    );
  }
}

final class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChildRadius.md),
        side: BorderSide(color: ChildColors.bad.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ChildSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline, color: ChildColors.bad, size: 22),
                SizedBox(width: ChildSpacing.sm),
                Text('Unable to Load Usage', style: ChildText.headline),
              ],
            ),
            const SizedBox(height: ChildSpacing.sm),
            Text(message ?? 'An error occurred while querying usage data.', style: ChildText.body),
            const SizedBox(height: ChildSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _UsageContentView extends StatelessWidget {
  const _UsageContentView({required this.controller});

  final ChildUsageController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DailyScreenTimeCard(
          totalDuration: controller.totalForegroundDuration,
          freshness: controller.freshness.value,
        ),
        const SizedBox(height: ChildSpacing.md),
        AppUsageListCard(appRecords: controller.appRecords),
      ],
    );
  }
}
