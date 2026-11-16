import 'package:flutter/material.dart';

import '../../../../app/theme/child_colors.dart';
import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';

/// Card displayed when Usage Access permission is denied or revoked.
final class UsagePermissionDeniedCard extends StatelessWidget {
  const UsagePermissionDeniedCard({
    required this.onOpenSettings,
    this.isOpeningSettings = false,
    this.errorMessage,
    super.key,
  });

  final VoidCallback onOpenSettings;
  final bool isOpeningSettings;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChildRadius.md),
        side: BorderSide(color: ChildColors.warning.withAlpha(100)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ChildSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock_clock_outlined,
                  color: ChildColors.warning,
                  size: 22,
                ),
                const SizedBox(width: ChildSpacing.sm),
                Expanded(
                  child: Text(
                    'Permission Required',
                    style: ChildText.headline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ChildSpacing.sm),
            Text(
              'To show daily screen time and application usage, Android requires '
              'Usage Access to be enabled in system settings.',
              style: ChildText.body,
            ),
            const SizedBox(height: ChildSpacing.sm),
            Text(
              'Tap below to open Android settings and turn on Usage Access for HAVEN.',
              style: ChildText.caption.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: ChildSpacing.sm),
              Text(
                errorMessage!,
                style: ChildText.caption.copyWith(color: ChildColors.bad),
              ),
            ],
            const SizedBox(height: ChildSpacing.md),
            SizedBox(
              width: double.infinity,
              height: ChildSpacing.touchTarget,
              child: FilledButton.icon(
                onPressed: isOpeningSettings ? null : onOpenSettings,
                icon: isOpeningSettings
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.settings_outlined),
                label: Text(
                  isOpeningSettings ? 'Opening Settings...' : 'Open Settings',
                  style: ChildText.label.copyWith(color: colorScheme.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
