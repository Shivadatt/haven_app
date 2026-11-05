import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_colors.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';

/// Dialog to rename a paired device.
class RenameDeviceDialog extends StatefulWidget {
  const RenameDeviceDialog({
    super.key,
    required this.initialName,
    required this.onRename,
  });

  final String initialName;
  final Future<bool> Function(String newName) onRename;

  static Future<bool?> show(
    BuildContext context, {
    required String initialName,
    required Future<bool> Function(String newName) onRename,
  }) => showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) =>
        RenameDeviceDialog(initialName: initialName, onRename: onRename),
  );

  @override
  State<RenameDeviceDialog> createState() => _RenameDeviceDialogState();
}

class _RenameDeviceDialogState extends State<RenameDeviceDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialName,
  );
  bool _isBusy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String trimmed = _nameController.text.trim();
    if (trimmed.isEmpty || trimmed.length > 80) {
      setState(() => _error = 'Enter a name between 1 and 80 characters.');
      return;
    }
    setState(() {
      _isBusy = true;
      _error = null;
    });

    final bool ok = await widget.onRename(trimmed);
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Could not rename device.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rename device', style: HavenText.headline),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HavenField(
            label: 'Device name',
            controller: _nameController,
            maxLength: 80,
            enabled: !_isBusy,
          ),
          if (_error != null) ...[
            const SizedBox(height: HavenSpacing.sm),
            Text(
              _error!,
              style: HavenText.caption.copyWith(color: HavenColors.bad),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isBusy ? null : _submit,
          child: _isBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
