import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../data/alerts_models.dart';

/// Why this screen is a list and not an inbox.
final class ReportLimitsCard extends StatelessWidget {
  const ReportLimitsCard({
    required this.board,
    required this.canRegister,
    required this.onOpenSettings,
    super.key,
  });

  final AlertBoard board;
  final bool canRegister;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'What you can do with this list',
    subtitle:
        'Read it. Nothing here can be marked, and nothing arrives on its own.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!canRegister)
          Text(
            'This is a read of the reports, not a delivery: the list shows what '
            'the backend had written when the screen read it. Nothing has '
            'registered this phone to be sent a notification about a new one.',
            style: HavenText.body,
          ),
        if (!canRegister) const SizedBox(height: HavenSpacing.md),
        BlockedNotice.fromFailure(board.deliveryGap),
        const SizedBox(height: HavenSpacing.md),
        BlockedNotice.fromFailure(board.ackGap),
        const SizedBox(height: HavenSpacing.md),
        Text(
          'Whether this phone is allowed to show notifications is asked on the '
          'settings screen, which owns that question.',
          style: HavenText.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: HavenSpacing.sm),
        HavenButton(
          label: 'Open settings',
          primary: false,
          onPressed: onOpenSettings,
        ),
      ],
    ),
  );
}
