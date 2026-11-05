import 'package:flutter/material.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_colors.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';

class ChildOption {
  const ChildOption({required this.userId, required this.name});
  final String userId;
  final String name;
}

/// Dialog to register a local/simulated device.
class AddDeviceDialog extends StatefulWidget {
  const AddDeviceDialog({
    super.key,
    required this.children,
    required this.onAdd,
  });

  final List<ChildOption> children;
  final Future<bool> Function({
    required String displayName,
    required String childUserId,
    String platform,
    int? batteryLevel,
  }) onAdd;

  static Future<bool?> show(
    BuildContext context, {
    required List<ChildOption> children,
    required Future<bool> Function({
      required String displayName,
      required String childUserId,
      String platform,
      int? batteryLevel,
    }) onAdd,
  }) => showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) =>
        AddDeviceDialog(children: children, onAdd: onAdd),
  );

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final TextEditingController _nameController = TextEditingController();
  late String? _selectedChildUserId =
      widget.children.isNotEmpty ? widget.children.first.userId : null;
  String _selectedPlatform = 'android';
  int _batteryLevel = 85;
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
    if (_selectedChildUserId == null) {
      setState(() => _error = 'Select a child for this device.');
      return;
    }
    setState(() {
      _isBusy = true;
      _error = null;
    });

    final bool ok = await widget.onAdd(
      displayName: trimmed,
      childUserId: _selectedChildUserId!,
      platform: _selectedPlatform,
      batteryLevel: _batteryLevel,
    );
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Could not add device.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add simulated device', style: HavenText.headline),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HavenField(
              label: 'Device name',
              controller: _nameController,
              maxLength: 80,
              helper: "e.g. Ivy's Tablet",
              enabled: !_isBusy,
            ),
            const SizedBox(height: HavenSpacing.md),
            Text('Assign to child', style: HavenText.caption),
            const SizedBox(height: HavenSpacing.xs),
            if (widget.children.isEmpty)
              Text('No children in family yet.', style: HavenText.body)
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedChildUserId,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  for (final ChildOption opt in widget.children)
                    DropdownMenuItem(value: opt.userId, child: Text(opt.name)),
                ],
                onChanged: _isBusy
                    ? null
                    : (String? next) =>
                        setState(() => _selectedChildUserId = next),
              ),
            const SizedBox(height: HavenSpacing.md),
            Text('Platform', style: HavenText.caption),
            const SizedBox(height: HavenSpacing.xs),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Android'),
                  selected: _selectedPlatform == 'android',
                  onSelected: _isBusy
                      ? null
                      : (bool s) {
                          if (s) setState(() => _selectedPlatform = 'android');
                        },
                ),
                const SizedBox(width: HavenSpacing.xs),
                ChoiceChip(
                  label: const Text('iOS'),
                  selected: _selectedPlatform == 'ios',
                  onSelected: _isBusy
                      ? null
                      : (bool s) {
                          if (s) setState(() => _selectedPlatform = 'ios');
                        },
                ),
              ],
            ),
            const SizedBox(height: HavenSpacing.md),
            Text('Battery level: $_batteryLevel%', style: HavenText.caption),
            Slider(
              value: _batteryLevel.toDouble(),
              min: 5,
              max: 100,
              divisions: 19,
              onChanged: _isBusy
                  ? null
                  : (double val) => setState(() => _batteryLevel = val.toInt()),
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
              : const Text('Add device'),
        ),
      ],
    );
  }
}
