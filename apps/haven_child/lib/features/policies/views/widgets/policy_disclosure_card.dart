import 'package:flutter/material.dart';

import '../../../../app/theme/child_colors.dart';
import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';

/// Mandatory non-enforcement disclosure banner clarifying that policies are
/// evaluated locally and OS-level blocking is not enforced on this build.
final class PolicyDisclosureCard extends StatelessWidget {
  const PolicyDisclosureCard({super.key, this.disclosureText});

  /// Evaluator-provided disclosure message.
  final String? disclosureText;

  static const String defaultDisclosure =
      'Policies are evaluated locally. '
      'Application blocking is not enforced on this build.';

  @override
  Widget build(BuildContext context) {
    final text = disclosureText ?? defaultDisclosure;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? ChildColors.darkTextSecondary.withAlpha(60)
        : ChildColors.textSecondary.withAlpha(60);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChildRadius.md),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ChildSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: ChildSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: ChildText.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
