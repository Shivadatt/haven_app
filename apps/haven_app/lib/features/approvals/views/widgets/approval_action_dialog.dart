import 'package:flutter/material.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../shared/components/haven_button.dart';
import '../../../../shared/components/haven_field.dart';
import '../../data/approval_models.dart';

class ApprovalActionDialog extends StatefulWidget {
  const ApprovalActionDialog({
    super.key,
    required this.request,
    required this.isApprove,
    required this.onConfirm,
  });

  final AppInstallRequest request;
  final bool isApprove;
  final void Function(String? note) onConfirm;

  @override
  State<ApprovalActionDialog> createState() => _ApprovalActionDialogState();
}

class _ApprovalActionDialogState extends State<ApprovalActionDialog> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isApprove ? 'Approve App Install' : 'Reject App Install';

    return AlertDialog(
      title: Text(title, style: HavenText.headline),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.request.childName} requested to install ${widget.request.appName} (${widget.request.category}).',
              style: HavenText.body,
            ),
            const SizedBox(height: HavenSpacing.sm),
            Text(
              'Package: ${widget.request.packageName}',
              style: HavenText.caption,
            ),
            const SizedBox(height: HavenSpacing.md),
            HavenField(
              label: 'Parent note (optional)',
              controller: _noteController,
              helper: 'e.g. For homework use only',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        HavenButton(
          label: widget.isApprove ? 'Approve' : 'Reject',
          primary: widget.isApprove,
          onPressed: () {
            Navigator.of(context).pop();
            final note = _noteController.text.trim();
            widget.onConfirm(note.isEmpty ? null : note);
          },
        ),
      ],
    );
  }
}
