import 'package:flutter/material.dart';

import '../../../../app/theme/haven_spacing.dart';

/// Interactive chip selector and adder for allowed app package exceptions.
class ScheduleAppExceptionsPicker extends StatefulWidget {
  const ScheduleAppExceptionsPicker({
    required this.allowedApps,
    required this.onChanged,
    super.key,
  });

  final List<String> allowedApps;
  final ValueChanged<List<String>> onChanged;

  @override
  State<ScheduleAppExceptionsPicker> createState() => _ScheduleAppExceptionsPickerState();
}

class _ScheduleAppExceptionsPickerState extends State<ScheduleAppExceptionsPicker> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final text = _ctrl.text.trim();
    if (text.isNotEmpty && !widget.allowedApps.contains(text)) {
      final updated = List<String>.from(widget.allowedApps)..add(text);
      widget.onChanged(updated);
      _ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 4,
          children: [
            for (final app in widget.allowedApps)
              Chip(
                label: Text(app.split('.').last),
                onDeleted: () {
                  final updated = List<String>.from(widget.allowedApps)..remove(app);
                  widget.onChanged(updated);
                },
              ),
          ],
        ),
        const SizedBox(height: HavenSpacing.xs),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. com.android.calculator2',
                  isDense: true,
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add app exception',
              onPressed: _add,
            ),
          ],
        ),
      ],
    );
  }
}
