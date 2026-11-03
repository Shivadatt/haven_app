import 'package:flutter/material.dart';

import '../../app/theme/haven_colors.dart';
import '../../app/theme/haven_spacing.dart';
import '../../app/theme/haven_text.dart';

/// How a state should read at a glance. `blocked` is separate from `bad`
/// because "the specification is missing" is not something a parent did wrong.
enum StatusTone { neutral, good, warning, bad, blocked }

/// A short status label. Colour is never the only signal: the words carry the
/// meaning, so the chip still reads in greyscale or for a colour-blind parent.
final class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.tone,
    this.icon,
    super.key,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color foreground = _foreground(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(HavenRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HavenSpacing.sm,
          vertical: HavenSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: HavenSpacing.xs),
            ],
            Text(label, style: HavenText.label.copyWith(color: foreground)),
          ],
        ),
      ),
    );
  }

  Color _foreground(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return switch (tone) {
      StatusTone.neutral =>
        dark ? HavenColors.darkTextSecondary : HavenColors.textSecondary,
      StatusTone.good => dark ? HavenColors.darkGood : HavenColors.good,
      StatusTone.warning =>
        dark ? HavenColors.darkWarning : HavenColors.warning,
      StatusTone.bad => dark ? HavenColors.darkBad : HavenColors.bad,
      StatusTone.blocked =>
        dark ? HavenColors.darkBlocked : HavenColors.blocked,
    };
  }
}
