import 'package:flutter/material.dart';

import '../../app/theme/haven_text.dart';

/// One labelled text entry. Validation messages are written to say what to do,
/// not what the schema rejected.
final class HavenField extends StatelessWidget {
  const HavenField({
    required this.label,
    this.helper,
    this.validator,
    this.controller,
    this.keyboardType,
    this.obscure = false,
    this.maxLength,
    this.autofillHint,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String? helper;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscure;
  final int? maxLength;
  final String? autofillHint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      enabled: enabled,
      autofillHints: autofillHint == null ? null : [autofillHint!],
      style: HavenText.body,
      // Two lines of visible text at the smallest size keeps the field a
      // comfortable tap target without inflating the layout.
      minLines: 1,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 3,
        counterText: '',
      ),
    );
  }
}
