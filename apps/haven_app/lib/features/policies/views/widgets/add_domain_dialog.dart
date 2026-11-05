import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../controllers/web_filter_controller.dart';
import '../../data/policy_rules.dart';
import '../../data/web_filter_models.dart';

class AddDomainDialog extends StatefulWidget {
  const AddDomainDialog({
    required this.controller,
    required this.initialBlocked,
    super.key,
  });

  final WebFilterController controller;
  final bool initialBlocked;

  static Future<void> show(
    BuildContext context, {
    required WebFilterController controller,
    required bool initialBlocked,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AddDomainDialog(
        controller: controller,
        initialBlocked: initialBlocked,
      ),
    );
  }

  @override
  State<AddDomainDialog> createState() => _AddDomainDialogState();
}

class _AddDomainDialogState extends State<AddDomainDialog> {
  late bool _isBlocked;
  final TextEditingController _domainCtrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _isBlocked = widget.initialBlocked;
  }

  @override
  void dispose() {
    _domainCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _domainCtrl.text.trim();
    final normalized = WebFilterModels.normalizeDomain(raw);
    final validation = PolicyRules.validateDomain(normalized);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    widget.controller.addDomain(normalized, isBlocked: _isBlocked);
    Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Domain Filter'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Block Domain')),
                ButtonSegment(value: false, label: Text('Allow Domain')),
              ],
              selected: {_isBlocked},
              onSelectionChanged: (set) => setState(() => _isBlocked = set.first),
            ),
            const SizedBox(height: HavenSpacing.md),
            TextField(
              controller: _domainCtrl,
              decoration: const InputDecoration(
                labelText: 'Domain Name',
                hintText: 'e.g. example.com or gaming.net',
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
        FilledButton(onPressed: _submit, child: const Text('Save Domain')),
      ],
    );
  }
}
