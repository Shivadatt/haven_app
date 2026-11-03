import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';

import '../../app/theme/haven_colors.dart';
import '../../app/theme/haven_spacing.dart';
import '../../app/theme/haven_text.dart';
import '../../core/constants/haven_config.dart';

/// A one-line statement of what this build can actually reach.
///
/// Shown while the staging endpoints are absent — which is the state of this
/// repository until `A2′(a)`, `A3`, `A12-R` and `A13` are signed. It is not an
/// error and it is not hidden: every data screen carries it, so a parent can
/// never mistake an empty dashboard for a quiet child.
final class BackendBanner extends StatelessWidget {
  const BackendBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<HavenConfig>()) return const SizedBox.shrink();
    final HavenConfig config = Get.find<HavenConfig>();
    final String message = config.status.message;
    if (config.status.readiness == BackendReadiness.configured) {
      return const SizedBox.shrink();
    }

    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color tone = dark ? HavenColors.darkWarning : HavenColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: HavenSpacing.gutter,
        vertical: HavenSpacing.sm,
      ),
      color: tone.withValues(alpha: 0.10),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: tone),
          const SizedBox(width: HavenSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: HavenText.caption.copyWith(color: tone),
            ),
          ),
        ],
      ),
    );
  }
}
