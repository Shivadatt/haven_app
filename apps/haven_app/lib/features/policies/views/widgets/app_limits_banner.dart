import 'package:flutter/material.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';

final class AppLimitsBanner extends StatelessWidget {
  const AppLimitsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HavenSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(HavenSpacing.xs),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 20),
          const SizedBox(width: HavenSpacing.xs),
          Expanded(
            child: Text(
              'LOCAL POLICY CONFIGURATION ONLY — Per-app time limits are stored '
              'locally. OS enforcement requires child companion native service in Phase 3.',
              style: HavenText.caption.copyWith(color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
