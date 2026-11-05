import 'package:flutter/material.dart';

/// Interactive chip selector for days of the week (1=Mon .. 7=Sun).
class ScheduleDaysPicker extends StatelessWidget {
  const ScheduleDaysPicker({
    required this.selectedDays,
    required this.onChanged,
    super.key,
  });

  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  static const List<String> _labels = ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        for (int i = 1; i <= 7; i++)
          FilterChip(
            label: Text(_labels[i]),
            selected: selectedDays.contains(i),
            onSelected: (sel) {
              final list = List<int>.from(selectedDays);
              if (sel) {
                list.add(i);
              } else if (list.length > 1) {
                list.remove(i);
              }
              onChanged(list);
            },
          ),
      ],
    );
  }
}
