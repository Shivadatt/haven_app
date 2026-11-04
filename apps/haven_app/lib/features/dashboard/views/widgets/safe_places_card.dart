import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';

/// The entry to the named places.
///
/// Separate from the device card on purpose: a place is something the parent
/// writes, while the device lane is something this build cannot read at all.
/// Putting the one working write under a wall of refusals would make it look
/// refused too.
class SafePlacesCard extends StatelessWidget {
  const SafePlacesCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Safe places',
    subtitle: 'Circles the family has named.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A place is a name, a position and a width. This build can change all '
          'three on a place that already exists, and can remove one. It cannot '
          'say whether a device is inside a place — that answer is not readable '
          'from here.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(
          label: 'Open safe places',
          primary: false,
          onPressed: onOpen,
        ),
      ],
    ),
  );
}
