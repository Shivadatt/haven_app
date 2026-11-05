import 'package:flutter/material.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';

final class WebFilterBanner extends StatelessWidget {
  const WebFilterBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HavenSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(HavenSpacing.xs),
        border: Border.all(color: Colors.purple.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.language_rounded, color: Colors.purple.shade800, size: 20),
          const SizedBox(width: HavenSpacing.xs),
          Expanded(
            child: Text(
              'LOCAL RULES ONLY — No real VPN or browser inspection in Phase 2. '
              'Domain filters and SafeSearch preferences are saved to the policy profile.',
              style: HavenText.caption.copyWith(color: Colors.purple.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
