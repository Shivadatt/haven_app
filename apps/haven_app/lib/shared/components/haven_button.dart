import 'package:flutter/material.dart';

import '../../app/theme/haven_spacing.dart';
import '../../app/theme/haven_text.dart';

/// The app's only button.
///
/// [onPressed] is nullable on purpose: a screen that cannot act yet passes null
/// and the button reads as disabled, instead of tappable and then doing nothing.
/// [busy] keeps the label in place and blocks re-entry, so a slow network never
/// invites a second tap that would send a second command.
final class HavenButton extends StatelessWidget {
  const HavenButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
    this.primary = true,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  final bool primary;

  /// Full width when true — used for the one action a screen is about.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? action = busy ? null : onPressed;
    final Widget child = busy
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : _content(context);

    final Widget button = primary
        ? FilledButton(onPressed: action, child: child)
        : OutlinedButton(onPressed: action, child: child);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: HavenSpacing.touchTarget,
        minWidth: expand ? double.infinity : 0,
      ),
      child: button,
    );
  }

  Widget _content(BuildContext context) {
    if (icon == null) return Text(label, style: HavenText.label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: HavenSpacing.sm),
        Text(label, style: HavenText.label),
      ],
    );
  }
}
