import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../controllers/web_filter_controller.dart';
import '../../data/policy_rules.dart';
import '../../data/web_filter_models.dart';

class EditDomainDialog extends StatefulWidget {
  const EditDomainDialog({
    required this.controller,
    required this.oldDomain,
    required this.isBlocked,
    super.key,
  });

  final WebFilterController controller;
  final String oldDomain;
  final bool isBlocked;

  static Future<void> show(
    BuildContext context, {
    required WebFilterController controller,
    required String oldDomain,
    required bool isBlocked,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => EditDomainDialog(
        controller: controller,
        oldDomain: oldDomain,
        isBlocked: isBlocked,
      ),
    );
  }

  @override
  State<EditDomainDialog> createState() => _EditDomainDialogState();
}

class _EditDomainDialogState extends State<EditDomainDialog> {
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.oldDomain);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _ctrl.text.trim();
    final normalized = WebFilterModels.normalizeDomain(raw);
    final validation = PolicyRules.validateDomain(normalized);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    widget.controller.editDomain(
      widget.oldDomain,
      normalized,
      isBlocked: widget.isBlocked,
    );
    Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Domain Rule'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(labelText: 'Domain Name'),
            onChanged: (_) => setState(() => _error = null),
          ),
          if (_error != null) ...[
            const SizedBox(height: HavenSpacing.xs),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: Get.back<void>, child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Update')),
      ],
    );
  }
}
