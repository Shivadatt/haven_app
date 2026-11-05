import 'package:flutter/material.dart';
import '../../../../app/theme/haven_colors.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../shared/components/section_card.dart';
import '../../../../shared/components/status_chip.dart';
import '../../data/approval_models.dart';
import 'extension_action_dialog.dart';

class ExtensionRequestCard extends StatelessWidget {
  const ExtensionRequestCard({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final ScreenTimeExtensionRequest request;
  final void Function(int granted, String? note) onApprove;
  final void Function(String? note) onReject;

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == ApprovalStatus.pending;

    return SectionCard(
      title: '${request.childName} • +${request.requestedMinutes} min request',
      subtitle: 'Daily limit: ${request.currentLimitMinutes} min',
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
              const CircleAvatar(
                backgroundColor: HavenColors.surface,
                child: Icon(Icons.timer_outlined, color: HavenColors.primary),
              ),
              const SizedBox(width: HavenSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (request.reason != null && request.reason!.isNotEmpty)
                      Text('"${request.reason}"', style: HavenText.body),
                    Text(
                      'Requested ${_formatTime(request.requestedAt)}',
                      style: HavenText.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (request.status == ApprovalStatus.approved &&
              request.grantedMinutes != null) ...[
            const SizedBox(height: HavenSpacing.sm),
            Text(
              'Granted extension: +${request.grantedMinutes} minutes',
              style: HavenText.body,
            ),
          ],
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
                      builder: (c) => ExtensionActionDialog(
                        request: request,
                        isApprove: false,
                        onConfirm: (_, note) => onReject(note),
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
                      builder: (c) => ExtensionActionDialog(
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
