import 'package:flutter/material.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';

/// Selector to associate a safe zone with a specific child or all children.
class ZoneChildSelector extends StatelessWidget {
  const ZoneChildSelector({
    required this.selectedChild,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final String selectedChild;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Child Association', style: HavenText.caption.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: HavenSpacing.xs),
        Wrap(
          spacing: 6,
          children: [
            for (final opt in options)
              ChoiceChip(
                label: Text(opt),
                selected: selectedChild == opt,
                onSelected: (selected) {
                  if (selected) onChanged(opt);
                },
              ),
          ],
        ),
      ],
    );
  }
}
