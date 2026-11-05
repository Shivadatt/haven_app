import 'package:flutter/material.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/schedules_editor_controller.dart';
import '../../data/policy_schedules.dart';
import '../../data/schedule_conflicts.dart';
import 'schedule_app_exceptions_picker.dart';
import 'schedule_days_picker.dart';

/// Interactive dialog for editing or creating a schedule.
class ScheduleFormDialog extends StatefulWidget {
  const ScheduleFormDialog({
    required this.controller,
    required this.initial,
    super.key,
  });

  final SchedulesEditorController controller;
  final PolicySchedule initial;

  static Future<void> show(
    BuildContext context, {
    required SchedulesEditorController controller,
    required PolicySchedule schedule,
  }) =>
      showDialog<void>(
        context: context,
        builder: (_) => ScheduleFormDialog(controller: controller, initial: schedule),
      );

  @override
  State<ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<ScheduleFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  late final TextEditingController _categoryCtrl;
  late List<int> _days;
  late List<String> _allowedApps;
  late bool _isActive;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial.name);
    _startCtrl = TextEditingController(text: widget.initial.startTime);
    _endCtrl = TextEditingController(text: widget.initial.endTime);
    _categoryCtrl = TextEditingController(text: widget.initial.category ?? '');
    _days = List<int>.from(widget.initial.days);
    _allowedApps = List<String>.from(widget.initial.allowedApps);
    _isActive = widget.initial.isActive;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  bool get _isOvernight {
    final s = _startCtrl.text.trim();
    final e = _endCtrl.text.trim();
    if (!PolicySchedule.isValidTime(s) || !PolicySchedule.isValidTime(e)) return false;
    return s.compareTo(e) > 0;
  }

  PolicySchedule _buildCurrent() => PolicySchedule(
    id: widget.initial.id,
    name: _nameCtrl.text.trim(),
    type: widget.initial.type,
    startTime: _startCtrl.text.trim(),
    endTime: _endCtrl.text.trim(),
    days: _days,
    isActive: _isActive,
    allowedApps: _allowedApps,
    category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
  );

  @override
  Widget build(BuildContext context) {
    final current = _buildCurrent();
    final conflicts = ScheduleConflictDetector.findConflicts(
      candidate: current,
      existingList: widget.controller.schedules,
    );

    return AlertDialog(
      title: Text('Edit ${widget.initial.type.label}'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Schedule Name'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: HavenSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startCtrl,
                      decoration: const InputDecoration(labelText: 'Start (HH:mm)'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: HavenSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _endCtrl,
                      decoration: const InputDecoration(labelText: 'End (HH:mm)'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              if (_isOvernight) ...[
                const SizedBox(height: HavenSpacing.xs),
                const Chip(
                  avatar: Icon(Icons.nightlight_round, size: 16),
                  label: Text('Overnight schedule (next morning)'),
                ),
              ],
              const SizedBox(height: HavenSpacing.sm),
              const Text('Active Days:', style: TextStyle(fontWeight: FontWeight.bold)),
              ScheduleDaysPicker(
                selectedDays: _days,
                onChanged: (days) => setState(() => _days = days),
              ),
              if (widget.initial.type == PolicyScheduleType.custom) ...[
                const SizedBox(height: HavenSpacing.sm),
                TextField(
                  controller: _categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Category (e.g. Focus, Homework)'),
                ),
              ],
              const SizedBox(height: HavenSpacing.sm),
              Text(
                widget.initial.type == PolicyScheduleType.bedtime
                    ? 'Allowed Emergency Exceptions'
                    : 'Allowed App Exceptions (${_allowedApps.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ScheduleAppExceptionsPicker(
                allowedApps: _allowedApps,
                onChanged: (apps) => setState(() => _allowedApps = apps),
              ),
              if (conflicts.isNotEmpty) ...[
                const SizedBox(height: HavenSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(HavenSpacing.xs),
                  color: Colors.amber.withValues(alpha: 0.2),
                  child: Text(
                    'Warning: ${conflicts.first.summary}',
                    style: HavenText.caption.copyWith(color: Colors.brown),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: HavenSpacing.xs),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final cand = _buildCurrent();
            final ok = await widget.controller.saveSchedule(cand);
            if (!context.mounted) return;
            if (ok) {
              Navigator.of(context).pop();
            } else {
              setState(() => _error = widget.controller.errorMessage.value);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
