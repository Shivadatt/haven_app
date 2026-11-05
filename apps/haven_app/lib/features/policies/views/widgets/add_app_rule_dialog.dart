import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../controllers/app_rules_controller.dart';
import '../../data/app_catalogue.dart';
import '../../data/policy_rules.dart';

class AddAppRuleDialog extends StatefulWidget {
  const AddAppRuleDialog({
    required this.controller,
    required this.initialBlocked,
    super.key,
  });

  final AppRulesController controller;
  final bool initialBlocked;

  static Future<void> show(
    BuildContext context, {
    required AppRulesController controller,
    required bool initialBlocked,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AddAppRuleDialog(
        controller: controller,
        initialBlocked: initialBlocked,
      ),
    );
  }

  @override
  State<AddAppRuleDialog> createState() => _AddAppRuleDialogState();
}

class _AddAppRuleDialogState extends State<AddAppRuleDialog> {
  late bool _isBlocked;
  final TextEditingController _customPkgCtrl = TextEditingController();
  AppCatalogueItem? _selectedItem;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isBlocked = widget.initialBlocked;
  }

  @override
  void dispose() {
    _customPkgCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final pkg = _selectedItem != null
        ? _selectedItem!.packageName
        : _customPkgCtrl.text.trim();

    final validation = PolicyRules.validatePackageName(pkg);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    widget.controller.setAppRule(pkg, isBlocked: _isBlocked);
    Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add App Rule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Allowed App')),
                ButtonSegment(value: true, label: Text('Blocked App')),
              ],
              selected: {_isBlocked},
              onSelectionChanged: (set) => setState(() => _isBlocked = set.first),
            ),
            const SizedBox(height: HavenSpacing.md),
            DropdownButtonFormField<AppCatalogueItem?>(
              initialValue: _selectedItem,
              decoration: const InputDecoration(labelText: 'Catalogue App'),
              hint: const Text('Select from catalogue'),
              items: [
                const DropdownMenuItem(value: null, child: Text('(Custom package)')),
                ...AppCatalogue.catalogue.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text('${item.name} (${item.category.label})'),
                  );
                }),
              ],
              onChanged: (item) {
                setState(() {
                  _selectedItem = item;
                  if (item != null) _customPkgCtrl.text = item.packageName;
                });
              },
            ),
            const SizedBox(height: HavenSpacing.sm),
            TextField(
              controller: _customPkgCtrl,
              enabled: _selectedItem == null,
              decoration: const InputDecoration(
                labelText: 'Package Name',
                hintText: 'com.example.app',
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            if (_error != null) ...[
              const SizedBox(height: HavenSpacing.xs),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: Get.back<void>, child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Add Rule')),
      ],
    );
  }
}
