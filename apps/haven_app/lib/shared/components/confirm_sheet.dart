import 'package:flutter/material.dart';

import '../../app/theme/haven_colors.dart';
import '../../app/theme/haven_spacing.dart';
import '../../app/theme/haven_text.dart';

/// Confirmation for anything that removes a device, unlinks a child or ends a
/// session. Returns whether the parent chose to go ahead.
///
/// The destructive case is deliberately harder to complete than the ordinary
/// one: the label repeats the action, and dismissing the sheet is the easy path.
abstract final class ConfirmSheet {
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
    String cancelLabel = 'Cancel',
  }) async {
    final bool? answer = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title, style: HavenText.headline),
        content: SingleChildScrollView(
          child: Text(body, style: HavenText.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: HavenColors.bad,
                    foregroundColor: HavenColors.onPrimary,
                  )
                : null,
            child: Text(confirmLabel, style: HavenText.label),
          ),
        ],
      ),
    );
    // Anything other than an explicit "yes" is a no.
    return answer ?? false;
  }

  /// The sheet variant for actions that need room to explain themselves.
  static Future<bool> sheet(
    BuildContext context, {
    required String title,
    required List<String> points,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final bool? answer = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HavenSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: HavenText.title),
              const SizedBox(height: HavenSpacing.md),
              for (final String point in points)
                Padding(
                  padding: const EdgeInsets.only(bottom: HavenSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(point, style: HavenText.body)),
                    ],
                  ),
                ),
              const SizedBox(height: HavenSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      child: const Text('Not now'),
                    ),
                  ),
                  const SizedBox(width: HavenSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return answer ?? false;
  }
}
