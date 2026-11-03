import 'package:flutter/material.dart';

import '../../app/theme/haven_spacing.dart';
import '../../app/theme/haven_text.dart';

/// A titled block of related content. One flat surface with a hairline border —
/// never a card inside a card.
final class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(HavenSpacing.md),
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: HavenText.headline),
                      if (subtitle != null) ...[
                        const SizedBox(height: HavenSpacing.xs),
                        Text(
                          subtitle!,
                          style: HavenText.caption.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: HavenSpacing.sm),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: HavenSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
