import 'package:flutter/material.dart';
import '../../../../app/theme/haven_colors.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../shared/components/section_card.dart';
import '../../../../shared/components/status_chip.dart';
import '../../data/approval_models.dart';
import 'approval_action_dialog.dart';

class ApprovalCard extends StatelessWidget {
  const ApprovalCard({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final AppInstallRequest request;
  final void Function(String? note) onApprove;
  final void Function(String? note) onReject;

  IconData _categoryIcon(String category) => switch (category.toLowerCase()) {
        'games' => Icons.sports_esports_rounded,
        'education' => Icons.school_rounded,
        'social' => Icons.people_rounded,
        'music' => Icons.music_note_rounded,
        _ => Icons.apps_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == ApprovalStatus.pending;

    return SectionCard(
      title: request.appName,
      subtitle: '${request.category} • for ${request.childName}',
      trailing: isPending
          ? const StatusChip(label: 'Pending', tone: StatusTone.warning)
          : StatusChip(
              label: request.status.label,
              tone: request.status == ApprovalStatus.approved
                  ? StatusTone.good
                  : StatusTone.blocked,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: HavenColors.surface,
                child: Icon(_categoryIcon(request.category), color: HavenColors.primary),
              ),
              const SizedBox(width: HavenSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.packageName, style: HavenText.caption),
                    Text(
                      'Requested ${_formatTime(request.requestedAt)}',
                      style: HavenText.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (request.parentNote != null && request.parentNote!.isNotEmpty) ...[
            const SizedBox(height: HavenSpacing.sm),
            Container(
              padding: const EdgeInsets.all(HavenSpacing.sm),
              decoration: BoxDecoration(
                color: HavenColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Note: ${request.parentNote}',
                style: HavenText.caption,
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: HavenSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (c) => ApprovalActionDialog(
                        request: request,
                        isApprove: false,
                        onConfirm: onReject,
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: HavenSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (c) => ApprovalActionDialog(
                        request: request,
                        isApprove: true,
                        onConfirm: onApprove,
                      ),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
