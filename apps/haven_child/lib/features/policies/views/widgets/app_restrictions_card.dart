import 'package:flutter/material.dart';
import 'package:haven_models/haven_models.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/status_chip.dart';

/// Renders blocked apps, per-app limits, and quota-exempt allowed apps.
final class AppRestrictionsCard extends StatelessWidget {
  const AppRestrictionsCard({
    required this.blockedApps,
    required this.allowedApps,
    required this.appLimits,
    this.appEvaluations = const <String, AppEvaluation>{},
    super.key,
  });

  final List<String> blockedApps;
  final List<String> allowedApps;
  final Map<String, int> appLimits;
  final Map<String, AppEvaluation> appEvaluations;

  static const String exemptTitle =
      'Always Allowed — Exempt from Global Daily Screen-Time Quota';

  static const String exemptSubtitle =
      'These apps are exempt from the global daily screen-time quota. '
      'Other applicable rules may still apply.';

  static const String nonEnforcementNotice =
      'Parent rules specify these apps as blocked. '
      'Application blocking is not enforced on this build.';

  @override
  Widget build(BuildContext context) {
    final hasRules =
        blockedApps.isNotEmpty ||
        appLimits.isNotEmpty ||
        allowedApps.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ChildSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App rules', style: ChildText.headline),
            const SizedBox(height: ChildSpacing.md),
            if (!hasRules)
              Text('No app rules configured.', style: ChildText.body)
            else ...[
              if (blockedApps.isNotEmpty) ...[
                Text('Blocked apps', style: ChildText.label),
                const SizedBox(height: ChildSpacing.xs),
                for (final pkg in blockedApps) ...[
                  Row(
                    children: [
                      Expanded(child: Text(pkg, style: ChildText.body)),
                      const ChildStatusChip(
                        key: ValueKey('app-blocked-chip'),
                        label: 'Blocked',
                        tone: StatusTone.bad,
                      ),
                    ],
                  ),
                  const SizedBox(height: ChildSpacing.xs),
                ],
                const SizedBox(height: ChildSpacing.xs),
                Text(nonEnforcementNotice, style: ChildText.caption),
                const SizedBox(height: ChildSpacing.md),
              ],
              if (appLimits.isNotEmpty) ...[
                Text('App time limits', style: ChildText.label),
                const SizedBox(height: ChildSpacing.xs),
                for (final entry in appLimits.entries) ...[
                  Row(
                    children: [
                      Expanded(child: Text(entry.key, style: ChildText.body)),
                      Text(
                        '${entry.value} min limit',
                        style: ChildText.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: ChildSpacing.xs),
                ],
                const SizedBox(height: ChildSpacing.md),
              ],
              if (allowedApps.isNotEmpty) ...[
                Text(exemptTitle, style: ChildText.label),
                const SizedBox(height: ChildSpacing.xs),
                Text(exemptSubtitle, style: ChildText.caption),
                const SizedBox(height: ChildSpacing.xs),
                for (final pkg in allowedApps) ...[
                  Row(
                    children: [
                      Expanded(child: Text(pkg, style: ChildText.body)),
                      const ChildStatusChip(
                        key: ValueKey('app-exempt-chip'),
                        label: 'Exempt',
                        tone: StatusTone.good,
                      ),
                    ],
                  ),
                  const SizedBox(height: ChildSpacing.xs),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}
