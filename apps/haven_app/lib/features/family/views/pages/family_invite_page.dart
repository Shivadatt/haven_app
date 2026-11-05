import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../widgets/invite_form_card.dart';
import '../widgets/pending_invites_card.dart';

/// Screen for inviting co-parents/guardians and managing pending invites.
final class FamilyInvitePage extends StatelessWidget {
  const FamilyInvitePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HavenScaffold(
      title: 'Family invitations',
      showBack: true,
      body: HavenPageBody(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: HavenSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InviteFormCard(),
              SizedBox(height: HavenSpacing.md),
              PendingInvitesCard(),
            ],
          ),
        ),
      ),
    );
  }
}
