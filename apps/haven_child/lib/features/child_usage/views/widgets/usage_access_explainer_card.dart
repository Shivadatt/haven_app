import 'package:flutter/material.dart';

import '../../../../app/theme/child_colors.dart';
import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';

/// Transparent, child-friendly disclosure explaining Usage Access boundaries.
///
/// Discloses device-level foreground stats and explicitly details that messages,
/// keystrokes, camera, microphone, photos and screen contents are NEVER read,
/// and that usage data is processed locally and never sent to a cloud backend.
final class UsageAccessExplainerCard extends StatelessWidget {
  const UsageAccessExplainerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChildRadius.md),
        side: BorderSide(color: colorScheme.outline.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ChildSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: ChildSpacing.sm),
                Expanded(
                  child: Text(
                    'About Usage Access',
                    style: ChildText.headline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ChildSpacing.sm),
            Text(
              'Usage Access allows this app to read daily screen time and how long '
              'each app is used on this device.',
              style: ChildText.body,
            ),
            const SizedBox(height: ChildSpacing.md),
            Text(
              'Your privacy is protected:',
              style: ChildText.label.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: ChildSpacing.xs),
            _PrivacyItem(
              icon: Icons.lock_outline,
              text: 'Processed entirely on this device — never sent to a cloud backend.',
            ),
            _PrivacyItem(
              icon: Icons.visibility_off_outlined,
              text: 'Cannot read messages, photos, screen contents, or keystrokes.',
            ),
            _PrivacyItem(
              icon: Icons.mic_off_outlined,
              text: 'Cannot access camera, microphone, or device location.',
            ),
            _PrivacyItem(
              icon: Icons.settings_suggest_outlined,
              text: 'Controlled entirely by Android system settings.',
            ),
          ],
        ),
      ),
    );
  }
}

final class _PrivacyItem extends StatelessWidget {
  const _PrivacyItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: ChildSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: ChildColors.good),
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
    );
  }
}
