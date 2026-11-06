import 'package:flutter/material.dart';

import '../../app/theme/child_colors.dart';
import '../../app/theme/child_spacing.dart';
import '../../app/theme/child_text.dart';

/// How a state should read at a glance. `blocked` is separate from `bad`:
/// "the specification or permission is missing" is not something the child
/// or parent did wrong. Same tone set as the parent's `StatusChip` so a
/// status reads identically across both apps.
enum StatusTone { neutral, good, warning, bad, blocked }

/// A short status label. Colour is never the only signal: the words carry
/// the meaning, so the chip still reads in greyscale.
final class ChildStatusChip extends StatelessWidget {
  const ChildStatusChip({
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
        borderRadius: BorderRadius.circular(ChildRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ChildSpacing.sm,
          vertical: ChildSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: ChildSpacing.xs),
            ],
            // Flexible so long honest labels ("Unavailable — not yet
            // implemented on this device build") wrap on narrow screens
            // instead of overflowing the row.
            Flexible(child: Text(label, style: ChildText.label.copyWith(color: foreground))),
          ],
        ),
      ),
    );
  }

  Color _foreground(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return switch (tone) {
      StatusTone.neutral =>
        dark ? ChildColors.darkTextSecondary : ChildColors.textSecondary,
      StatusTone.good => dark ? ChildColors.darkGood : ChildColors.good,
      StatusTone.warning =>
        dark ? ChildColors.darkWarning : ChildColors.warning,
      StatusTone.bad => dark ? ChildColors.darkBad : ChildColors.bad,
      StatusTone.blocked =>
        dark ? ChildColors.darkBlocked : ChildColors.blocked,
    };
  }
}
