import 'package:flutter/material.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/status_chip.dart';

/// Renders domain filtering rules and SafeSearch status.
final class WebRestrictionsCard extends StatelessWidget {
  const WebRestrictionsCard({
    required this.safeSearchEnabled,
    required this.blockedDomains,
    required this.allowedDomains,
    super.key,
  });

  final bool safeSearchEnabled;
  final List<String> blockedDomains;
  final List<String> allowedDomains;

  static const String nonEnforcementNotice =
      'Web restrictions are evaluated locally. '
      'Browser traffic is not filtered on this build.';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ChildSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Web rules', style: ChildText.headline)),
                ChildStatusChip(
                  key: const ValueKey('safesearch-chip'),
                  label: safeSearchEnabled ? 'SafeSearch on' : 'SafeSearch off',
                  tone: safeSearchEnabled
                      ? StatusTone.good
                      : StatusTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: ChildSpacing.md),
            if (blockedDomains.isEmpty && allowedDomains.isEmpty) ...[
              Text('No domain restrictions configured.', style: ChildText.body),
            ] else ...[
              if (blockedDomains.isNotEmpty) ...[
                Text('Blocked websites', style: ChildText.label),
                const SizedBox(height: ChildSpacing.xs),
                for (final domain in blockedDomains) ...[
                  Row(
                    children: [
                      Expanded(child: Text(domain, style: ChildText.body)),
                      const ChildStatusChip(
                        key: ValueKey('domain-blocked-chip'),
                        label: 'Blocked',
                        tone: StatusTone.bad,
                      ),
                    ],
                  ),
                  const SizedBox(height: ChildSpacing.xs),
                ],
                const SizedBox(height: ChildSpacing.xs),
              ],
              if (allowedDomains.isNotEmpty) ...[
                Text('Allowed websites', style: ChildText.label),
                const SizedBox(height: ChildSpacing.xs),
                for (final domain in allowedDomains) ...[
                  Row(
                    children: [
                      Expanded(child: Text(domain, style: ChildText.body)),
                      const ChildStatusChip(
                        key: ValueKey('domain-allowed-chip'),
                        label: 'Allowed',
                        tone: StatusTone.good,
                      ),
                    ],
                  ),
                  const SizedBox(height: ChildSpacing.xs),
                ],
                const SizedBox(height: ChildSpacing.xs),
              ],
              Text(nonEnforcementNotice, style: ChildText.caption),
            ],
          ],
        ),
      ),
    );
  }
}
