import 'package:flutter/material.dart';
import 'package:haven_core/haven_core.dart';

import '../../app/theme/child_colors.dart';
import '../../app/theme/child_spacing.dart';
import '../../app/theme/child_text.dart';

/// The child-facing twin of the parent's `BlockedNotice`: one plain-language
/// sentence plus the technical `missing` string, so the limitation is stated
/// honestly without hiding what is absent.
///
/// Colour is the calm `blocked` token — deliberately not red: a not-yet-built
/// feature is not the child's mistake.
final class ChildBlockedNotice extends StatelessWidget {
  const ChildBlockedNotice({
    required this.requirement,
    required this.missing,
    super.key,
  });

  final String requirement;
  final String missing;

  /// Convenience extraction of the two strings from any failure. Sealed
  /// `HavenFailure` cannot be type-tested from a widget, so the caller uses
  /// `Result.map`; this only formats what it is handed.
  factory ChildBlockedNotice.fromFailure(HavenFailure failure) =>
      ChildBlockedNotice(
        requirement: failure.message,
        missing: failure is BlockedFailure
            ? failure.missing
            : 'internal: ${failure.runtimeType}',
      );

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color blocked = dark ? ChildColors.darkBlocked : ChildColors.blocked;
    return Container(
      padding: const EdgeInsets.all(ChildSpacing.md),
      decoration: BoxDecoration(
        color: blocked.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(ChildRadius.md),
        border: Border.all(color: blocked.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(requirement, style: ChildText.body),
          const SizedBox(height: ChildSpacing.xs),
          Text('Missing: $missing', style: ChildText.caption),
        ],
      ),
    );
  }
}
