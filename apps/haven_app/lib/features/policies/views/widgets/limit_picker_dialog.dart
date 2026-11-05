import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/app_limits_controller.dart';
import '../../data/app_catalogue.dart';

class LimitPickerDialog extends StatefulWidget {
  const LimitPickerDialog({
    required this.item,
    required this.currentMinutes,
    required this.controller,
    super.key,
  });

  final AppCatalogueItem item;
  final int? currentMinutes;
  final AppLimitsController controller;

  static Future<void> show(
    BuildContext context, {
    required AppCatalogueItem item,
    required int? currentMinutes,
    required AppLimitsController controller,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => LimitPickerDialog(
        item: item,
        currentMinutes: currentMinutes,
        controller: controller,
      ),
    );
  }

  @override
  State<LimitPickerDialog> createState() => _LimitPickerDialogState();
}

class _LimitPickerDialogState extends State<LimitPickerDialog> {
  static const List<int> _presets = [15, 30, 45, 60, 120];
  late int _selectedMinutes;
  late final TextEditingController _customCtrl;
  bool _isCustom = false;

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.currentMinutes ?? 30;
    _isCustom = !_presets.contains(_selectedMinutes);
    _customCtrl = TextEditingController(text: '$_selectedMinutes');
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _confirmRemoval() {
    Get.dialog<void>(
      AlertDialog(
        title: const Text('Remove App Limit?'),
        content: Text('Remove daily screen time limit for ${widget.item.name}?'),
        actions: [
          TextButton(onPressed: Get.back<void>, child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              widget.controller.removeLimit(widget.item.packageName);
              Get.back<void>(); // close confirm
              Get.back<void>(); // close dialog
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Limit: ${widget.item.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item.packageName, style: HavenText.caption),
            const SizedBox(height: HavenSpacing.md),
            const Text('Choose daily time limit:'),
            const SizedBox(height: HavenSpacing.xs),
            Wrap(
              spacing: HavenSpacing.xs,
              runSpacing: HavenSpacing.xs,
              children: [
                ..._presets.map((mins) {
                  final label = mins >= 60 ? '${mins ~/ 60}h' : '${mins}m';
                  return ChoiceChip(
                    label: Text(label),
                    selected: !_isCustom && _selectedMinutes == mins,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _isCustom = false;
                          _selectedMinutes = mins;
                          _customCtrl.text = '$mins';
                        });
                      }
                    },
                  );
                }),
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: _isCustom,
                  onSelected: (selected) {
                    if (selected) setState(() => _isCustom = true);
                  },
                ),
              ],
            ),
            if (_isCustom) ...[
              const SizedBox(height: HavenSpacing.sm),
              TextField(
                controller: _customCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minutes per day',
                  suffixText: 'minutes',
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null && parsed > 0) _selectedMinutes = parsed;
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.currentMinutes != null)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _confirmRemoval,
            child: const Text('Remove'),
          ),
        TextButton(onPressed: Get.back<void>, child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            widget.controller.setLimit(widget.item.packageName, _selectedMinutes);
            Get.back<void>();
          },
          child: const Text('Save Limit'),
        ),
      ],
    );
  }
}
