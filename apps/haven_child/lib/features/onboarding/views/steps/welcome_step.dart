import 'package:flutter/material.dart';

import '../../../../app/theme/child_spacing.dart';
import '../../../../app/theme/child_text.dart';
import '../../../../shared/components/status_chip.dart';
import '../../../../core/session/child_local_session.dart';
import '../../domain/onboarding_steps.dart';

/// Step 1 — plain words about what this app is and, honestly, what it is
/// not yet. No promises, no decoration of the missing parent link.
final class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Hi! Let’s set up Haven on this device.', style: ChildText.headline),
      const SizedBox(height: ChildSpacing.md),
      const Text(
        'This app lives on this phone or tablet. What you enter here stays '
        'on the device. Features get added stage by stage, and each one '
        'will tell you exactly what it does before it starts.',
        style: ChildText.body,
      ),
      const SizedBox(height: ChildSpacing.lg),
      const ChildStatusChip(
        key: ValueKey('welcome-parent-connection'),
        label:
            '${ChildLocalSession.parentConnectionLabel}: '
            '${ChildLocalSession.parentConnectionStatus}',
        tone: StatusTone.neutral,
      ),
      const SizedBox(height: ChildSpacing.sm),
      const Text(
        'Nothing is monitored yet. Setup first, features later — you will '
        'always be told what is active.',
        style: ChildText.body,
      ),
      const SizedBox(height: ChildSpacing.md),
      Text(
        'Ready? There are ${OnboardingStep.count} short steps, and you can '
        'stop halfway and come back.',
        style: ChildText.caption,
      ),
    ],
  );
}
