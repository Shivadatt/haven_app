import 'package:flutter/material.dart';

import '../../../app/theme/child_spacing.dart';
import '../../../app/theme/child_text.dart';

/// A single labelled text field — the child-lane counterpart of the parent's
/// `HavenField`, kept tiny: label, optional helper/error line, one maxLength.
/// Validation itself stays in the controller/repository (haven_core), never
/// in this widget.
final class ChildField extends StatelessWidget {
  const ChildField({
    required this.label,
    required this.controller,
    this.helper,
    this.errorText,
    this.maxLength,
    this.enabled = true,
    this.keyboardType,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? helper;
  final String? errorText;
  final int? maxLength;
  final bool enabled;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: ChildText.label),
      const SizedBox(height: ChildSpacing.xs),
      TextField(
        controller: controller,
        enabled: enabled,
        maxLength: maxLength,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: label,
          helperText: helper,
          errorText: errorText,
          counterText: '',
          border: const OutlineInputBorder(),
        ),
      ),
    ],
  );
}
