import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';

/// The entry to the three device-side logs.
///
/// Instructions, rule versions and session records are the rows a parent can read
/// even though no device can be listed: all three tables carry a SELECT grant for
/// a parent, `devices` does not. All three screens are read-only, and this card
/// says so instead of letting a button find out.
class DeviceRecordsCard extends StatelessWidget {
  const DeviceRecordsCard({
    required this.onOpenCommands,
    required this.onOpenPolicies,
    required this.onOpenSessions,
    super.key,
  });

  final VoidCallback onOpenCommands;
  final VoidCallback onOpenPolicies;
  final VoidCallback onOpenSessions;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Device records',
    subtitle: 'Instructions sent, rule versions written, sessions asked for.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Each list comes from rows the backend already holds. None of them can '
          'be changed from this app: no client role may write those tables, and '
          'the functions that would are closed to the role this app signs in as.',
          style: HavenText.body,
        ),
        const SizedBox(height: HavenSpacing.md),
        HavenButton(
          label: 'Open instructions',
          primary: false,
          onPressed: onOpenCommands,
        ),
        const SizedBox(height: HavenSpacing.sm),
        HavenButton(
          label: 'Open rule versions',
          primary: false,
          onPressed: onOpenPolicies,
        ),
        const SizedBox(height: HavenSpacing.sm),
        HavenButton(
          label: 'Open session records',
          primary: false,
          onPressed: onOpenSessions,
        ),
      ],
    ),
  );
}
