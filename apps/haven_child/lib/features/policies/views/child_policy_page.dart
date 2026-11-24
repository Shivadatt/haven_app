import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/child_colors.dart';
import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/child_scaffold.dart';
import '../controllers/child_policy_controller.dart';
import '../data/child_policy_record.dart';
import 'widgets/app_restrictions_card.dart';
import 'widgets/daily_quota_card.dart';
import 'widgets/policy_disclosure_card.dart';
import 'widgets/policy_schedules_card.dart';
import 'widgets/policy_status_card.dart';
import 'widgets/web_restrictions_card.dart';

/// Main child policy screen displaying parent-managed rules and limits.
final class ChildPolicyPage extends StatelessWidget {
  const ChildPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChildPolicyController>();
    return ChildScaffold(
      title: 'Family Rules',
      actions: [
        IconButton(
          tooltip: 'Refresh rules',
          icon: const Icon(Icons.refresh),
          onPressed: () => _handleRefresh(controller),
        ),
      ],
      body: ChildPageBody(
        child: RefreshIndicator(
          onRefresh: () => _handleRefresh(controller),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: ChildSpacing.md),
            child: Obx(() => _buildBody(controller)),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh(ChildPolicyController controller) async {
    if (controller.status.value == ChildPolicyStatus.loading) return;
    final loadResult = await controller.loadPolicy();
    if (loadResult.isOk && controller.status.value == ChildPolicyStatus.ready) {
      await controller.evaluate();
    }
  }

  Widget _buildBody(ChildPolicyController controller) {
    return switch (controller.status.value) {
      ChildPolicyStatus.initial || ChildPolicyStatus.loading => const Padding(
        padding: EdgeInsets.symmetric(vertical: ChildSpacing.xl),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: ChildSpacing.md),
              Text('Loading device rules…', style: ChildText.body),
            ],
          ),
        ),
      ),
      ChildPolicyStatus.failure => _buildFailureView(controller),
      ChildPolicyStatus.ready => _buildContentView(controller),
    };
  }

  Widget _buildFailureView(ChildPolicyController controller) {
    final lastValid = controller.lastValidPolicy;
    final failureMsg =
        controller.policyFailure.value?.message ??
        'Unable to verify policy in local storage.';
    const heading = 'Rule Check Failed — Active Policy Suspended';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChildRadius.md),
        side: BorderSide(color: ChildColors.bad.withAlpha(120)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ChildSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: ChildColors.bad,
                  size: 22,
                ),
                const SizedBox(width: ChildSpacing.sm),
                Expanded(child: Text(heading, style: ChildText.headline)),
              ],
            ),
            const SizedBox(height: ChildSpacing.sm),
            Text(failureMsg, style: ChildText.body),
            if (lastValid != null) ...[
              const SizedBox(height: ChildSpacing.sm),
              Text(
                'Last verified version on record: v${lastValid.policyVersion ?? 1}. '
                'Currently inactive due to policy verification failure.',
                style: ChildText.caption,
              ),
            ],
            const SizedBox(height: ChildSpacing.md),
            OutlinedButton.icon(
              onPressed: () => controller.loadPolicy(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentView(ChildPolicyController controller) {
    final record = controller.activePolicy.value;
    final evaluation = controller.lastEvaluation.value;
    final config = record?.config ?? ChildPolicyRecord.inMemoryNeutralPolicy;
    final isNeutral = record?.isUnlimitedQuota ?? true;
    final isMidnight = _checkMidnight(controller.clock.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PolicyStatusCard(
          provenance: record?.provenance,
          status: controller.status.value,
          policyVersion: record?.policyVersion,
          updatedAt: record?.updatedAt,
          overallState: evaluation?.overallState,
          primaryReason: evaluation?.primaryReason,
        ),
        const SizedBox(height: ChildSpacing.md),
        DailyQuotaCard(
          configuredMinutes: config.dailyScreenTimeMinutes,
          isNeutral: isNeutral,
          quota: evaluation?.dailyQuota,
          isExactMidnight: isMidnight,
        ),
        const SizedBox(height: ChildSpacing.md),
        PolicySchedulesCard(
          schedules: config.schedules,
          activeSchedules:
              evaluation?.activeSchedules ?? const <PolicySchedule>[],
        ),
        const SizedBox(height: ChildSpacing.md),
        AppRestrictionsCard(
          blockedApps: config.blockedApps,
          allowedApps: config.allowedApps,
          appLimits: config.appLimits,
          appEvaluations:
              evaluation?.appEvaluations ?? const <String, AppEvaluation>{},
        ),
        const SizedBox(height: ChildSpacing.md),
        WebRestrictionsCard(
          safeSearchEnabled: config.safeSearchEnabled,
          blockedDomains: config.blockedDomains,
          allowedDomains: config.allowedDomains,
        ),
        const SizedBox(height: ChildSpacing.md),
        PolicyDisclosureCard(disclosureText: evaluation?.disclosure),
      ],
    );
  }

  bool _checkMidnight(DateTime dt) {
    final local = dt.toLocal();
    return local.hour == 0 &&
        local.minute == 0 &&
        local.second == 0 &&
        local.millisecond == 0;
  }
}
