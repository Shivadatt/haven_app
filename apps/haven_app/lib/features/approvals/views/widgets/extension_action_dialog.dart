import 'package:flutter/material.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../shared/components/haven_button.dart';
import '../../../../shared/components/haven_field.dart';
import '../../data/approval_models.dart';

class ExtensionActionDialog extends StatefulWidget {
  const ExtensionActionDialog({
    super.key,
    required this.request,
    required this.isApprove,
    required this.onConfirm,
  });

  final ScreenTimeExtensionRequest request;
  final bool isApprove;
  final void Function(int grantedMinutes, String? note) onConfirm;

  @override
  State<ExtensionActionDialog> createState() => _ExtensionActionDialogState();
}

class _ExtensionActionDialogState extends State<ExtensionActionDialog> {
  late int _selectedMinutes;
  final TextEditingController _customController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isCustom = false;

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.request.requestedMinutes;
  }

  @override
  void dispose() {
    _customController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isApprove ? 'Approve Screen-Time' : 'Reject Request';

    return AlertDialog(
      title: Text(title, style: HavenText.headline),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.request.childName} requested +${widget.request.requestedMinutes} minutes.',
              style: HavenText.body,
            ),
            if (widget.request.reason != null) ...[
              const SizedBox(height: HavenSpacing.xs),
              Text('Reason: ${widget.request.reason}', style: HavenText.caption),
            ],
            if (widget.isApprove) ...[
              const SizedBox(height: HavenSpacing.md),
              const Text('Grant duration:', style: HavenText.headline),
              const SizedBox(height: HavenSpacing.xs),
              Wrap(
                spacing: HavenSpacing.xs,
                children: [15, 30, 60].map((m) {
                  return ChoiceChip(
                    label: Text('+$m m'),
                    selected: !_isCustom && _selectedMinutes == m,
                    onSelected: (sel) {
                      if (sel) setState(() { _selectedMinutes = m; _isCustom = false; });
                    },
                  );
                }).toList()
                  ..add(
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: _isCustom,
                      onSelected: (sel) {
                        if (sel) setState(() => _isCustom = true);
                      },
                    ),
                  ),
              ),
              if (_isCustom) ...[
                const SizedBox(height: HavenSpacing.sm),
                HavenField(
                  label: 'Minutes',
                  controller: _customController,
                  helper: 'e.g. 45',
                ),
              ],
            ],
            const SizedBox(height: HavenSpacing.md),
            HavenField(
              label: 'Parent note (optional)',
              controller: _noteController,
              helper: 'e.g. Wrap up by dinner time',
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
            int granted = _selectedMinutes;
            if (_isCustom) {
              granted = int.tryParse(_customController.text.trim()) ?? _selectedMinutes;
            }
            final note = _noteController.text.trim();
            widget.onConfirm(granted, note.isEmpty ? null : note);
          },
        ),
      ],
    );
  }
}
