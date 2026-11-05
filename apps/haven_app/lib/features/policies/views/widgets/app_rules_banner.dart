import 'package:flutter/material.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';

final class AppRulesBanner extends StatelessWidget {
  const AppRulesBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HavenSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(HavenSpacing.xs),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: Colors.blue.shade800, size: 20),
          const SizedBox(width: HavenSpacing.xs),
          Expanded(
            child: Text(
              'LOCAL POLICY CONFIGURATION ONLY — Rules are saved locally to '
              'your profile. Full OS app blocking is enforced by child service in Phase 3.',
              style: HavenText.caption.copyWith(color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
