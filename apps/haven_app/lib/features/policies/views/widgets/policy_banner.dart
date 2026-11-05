import 'package:flutter/material.dart';

import '../../../../app/theme/haven_colors.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';

/// Prominent banner clarifying local configuration scope.
final class PolicyBanner extends StatelessWidget {
  const PolicyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HavenSpacing.md),
      decoration: BoxDecoration(
        color: HavenColors.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HavenColors.warning, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: HavenColors.warning,
            size: 22,
          ),
          const SizedBox(width: HavenSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOCAL CONFIGURATION ONLY — Device enforcement is deferred to child native phase',
                  style: HavenText.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: HavenColors.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: HavenSpacing.xs),
                Text(
                  'Policies configured here are saved into the local database and will be synced '
                  'once child native service enforcement activates.',
                  style: HavenText.caption.copyWith(
                    color: HavenColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
