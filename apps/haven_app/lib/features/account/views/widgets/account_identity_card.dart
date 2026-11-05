import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';
import 'package:haven_models/haven_models.dart' show ProfileRole;

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../data/account_repository.dart';

/// Read-only display of the signed-in session, role, and local/offline status.
final class AccountIdentityCard extends StatelessWidget {
  const AccountIdentityCard(this.info, {super.key});

  final AccountInfo info;

  @override
  Widget build(BuildContext context) {
    final ProfileRole? role = info.role;
    return SectionCard(
      title: 'Signed in as',
      subtitle: info.email ?? 'This session has no email on file.',
      trailing: Wrap(
        spacing: HavenSpacing.xs,
        children: [
          if (info.isOffline)
            const StatusChip(
              label: 'Local session',
              tone: StatusTone.good,
            ),
          StatusChip(
            label: role?.label ?? 'Role not set',
            tone: switch (role) {
              ProfileRole.parent => StatusTone.good,
              ProfileRole.child => StatusTone.warning,
              ProfileRole.unset || null => StatusTone.neutral,
            },
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info.isOffline) ...[
            Text(
              'Session mode: Local (Offline). All data and credentials stay on this device.',
              style: HavenText.caption,
            ),
            const SizedBox(height: HavenSpacing.xs),
          ],
          Text(
            'Only a parent account can set up a family. Haven does not change this '
            'role from the app — it is set once, by the service, when you confirm '
            'you are the child’s parent or guardian.',
            style: HavenText.body,
          ),
        ],
      ),
    );
  }
}
