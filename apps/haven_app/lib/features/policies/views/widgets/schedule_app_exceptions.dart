import 'package:flutter/material.dart';

class ScheduleAppExceptions extends StatefulWidget {
  const ScheduleAppExceptions({
    required this.allowedApps,
    required this.isBedtime,
    required this.onChanged,
    super.key,
  });

  final List<String> allowedApps;
  final bool isBedtime;
  final ValueChanged<List<String>> onChanged;

  @override
  State<ScheduleAppExceptions> createState() => _ScheduleAppExceptionsState();
}

class _ScheduleAppExceptionsState extends State<ScheduleAppExceptions> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isBedtime
              ? 'Allowed Emergency Exceptions'
              : 'Allowed App Exceptions (${widget.allowedApps.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Wrap(
          spacing: 4,
          children: [
            for (final app in widget.allowedApps)
              Chip(
                label: Text(app.split('.').last),
                onDeleted: () {
                  final next = List<String>.from(widget.allowedApps)..remove(app);
                  widget.onChanged(next);
                },
              ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. com.android.calculator2',
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final text = _ctrl.text.trim();
                if (text.isNotEmpty && !widget.allowedApps.contains(text)) {
                  final next = List<String>.from(widget.allowedApps)..add(text);
                  widget.onChanged(next);
                  _ctrl.clear();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
