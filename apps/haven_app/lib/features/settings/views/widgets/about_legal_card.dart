import 'package:flutter/material.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../shared/components/section_card.dart';
import '../../../../shared/components/status_chip.dart';

class AboutLegalCard extends StatelessWidget {
  const AboutLegalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Version & Build',
          subtitle: 'Haven 2.0.0 (Phase 2)',
          trailing: StatusChip(label: 'v2.0.0', tone: StatusTone.good),
          child: Text(
            'Phase 2 release with local offline approvals, screen time '
            'extensions, parental policies, and on-device support logging.',
            style: HavenText.body,
          ),
        ),
        SizedBox(height: HavenSpacing.md),
        SectionCard(
          title: 'Privacy & Offline Policy',
          trailing: StatusChip(label: 'Zero-Tracking', tone: StatusTone.good),
          child: Text(
            'Haven is engineered with an offline-first architecture. All app '
            'usage records, location check-ins, rule policies, and approval logs '
            'are stored on your own device in encrypted local tables. No third-party '
            'analytics, ad trackers, or unapproved servers receive your family data.',
            style: HavenText.body,
          ),
        ),
        SizedBox(height: HavenSpacing.md),
        SectionCard(
          title: 'Terms of Use & Safety Notes',
          child: Text(
            'Haven is designed exclusively for parental guardianship with full '
            'transparency to the child. Rules and limits are only enforced '
            'locally once acknowledged by the linked device.',
            style: HavenText.body,
          ),
        ),
      ],
    );
  }
}
