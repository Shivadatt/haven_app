import 'package:flutter/material.dart';

import '../../app/theme/child_spacing.dart';
import '../../app/theme/child_text.dart';

/// A label with its value on one line — the row shape shared by the device
/// screen and the onboarding device-review step, so "Unavailable" always
/// looks the same and is never re-invented per screen.
final class ChildInfoRow extends StatelessWidget {
  const ChildInfoRow({
    required this.label,
    required this.value,
    this.emphasizeUnavailable = true,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasizeUnavailable;

  @override
  Widget build(BuildContext context) {
    final Color secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ChildSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: ChildText.label)),
          const SizedBox(width: ChildSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: emphasizeUnavailable && _looksUnavailable
                  ? ChildText.label.copyWith(
                      color: secondary,
                      fontStyle: FontStyle.italic,
                    )
                  : ChildText.body,
            ),
          ),
        ],
      ),
    );
  }

  bool get _looksUnavailable => value.toLowerCase().contains('unavailable');
}
