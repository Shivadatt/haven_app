import 'package:flutter/material.dart';
import 'package:haven_core/haven_core.dart';

import '../../app/theme/haven_colors.dart';
import '../../app/theme/haven_spacing.dart';
import '../../app/theme/haven_text.dart';

/// Says, in one line, that a capability is not implemented because the
/// specification has it missing — and shows the technical reason underneath for
/// whoever has to write that specification.
///
/// This is never styled as an error: a blocked feature is a known boundary, not
/// a fault the parent caused.
final class BlockedNotice extends StatelessWidget {
  const BlockedNotice({required this.requirement, this.missing, super.key});

  /// What the parent needs to know, in their words.
  final String requirement;

  /// The `missing` string from [BlockedFailure] — what exactly is unspecified.
  final String? missing;

  factory BlockedNotice.fromFailure(BlockedFailure failure) =>
      BlockedNotice(requirement: failure.message, missing: failure.missing);

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color tone = dark ? HavenColors.darkBlocked : HavenColors.blocked;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HavenSpacing.md),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(HavenRadius.sm),
        border: Border.all(color: tone.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: tone, size: 20),
              const SizedBox(width: HavenSpacing.sm),
              Expanded(
                child: Text(
                  requirement,
                  style: HavenText.label.copyWith(color: tone),
                ),
              ),
            ],
          ),
          if (missing != null) ...[
            const SizedBox(height: HavenSpacing.sm),
            Text(
              'Not specified: $missing',
              style: HavenText.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
