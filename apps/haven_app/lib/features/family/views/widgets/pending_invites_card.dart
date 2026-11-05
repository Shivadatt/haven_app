import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../core/utils/haven_time.dart';
import '../../controllers/family_invite_controller.dart';
import '../../data/invitation_models.dart';

/// Card showing pending family invitations and cancellation controls.
final class PendingInvitesCard extends GetView<FamilyInviteController> {
  const PendingInvitesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Pending invitations',
      subtitle: 'Invitations awaiting partner acceptance',
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.pendingInvites.isEmpty) {
          return Text('No pending invitations.', style: HavenText.body);
        }
        return Column(
          children: [
            for (final invite in controller.pendingInvites)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(invite.email, style: HavenText.title),
                subtitle: Text(
                  'Role: ${invite.role.capitalizeFirst} • Sent: ${havenDay(invite.createdAt) ?? 'Recently'}',
                  style: HavenText.caption,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 20),
                      onPressed: () => _showDetail(context, invite),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                      onPressed: () => controller.cancelInvite(invite.id),
                    ),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }

  void _showDetail(BuildContext context, FamilyInvitation invite) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invitation details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recipient: ${invite.email}'),
            const SizedBox(height: HavenSpacing.xs),
            Text('Role: ${invite.role}'),
            const SizedBox(height: HavenSpacing.xs),
            Text('Status: ${invite.status}'),
            const SizedBox(height: HavenSpacing.xs),
            Text('ID: ${invite.id}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
