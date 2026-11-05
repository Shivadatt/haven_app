import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/widgets/widgets.dart';

import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../controllers/schedules_editor_controller.dart';
import '../../data/policy_schedules.dart';
import '../widgets/schedule_card_item.dart';
import '../widgets/schedule_form_dialog.dart';

/// Full-page editor for Bedtime, School Time, and Custom schedules.
final class SchedulesEditorPage extends GetView<SchedulesEditorController> {
  const SchedulesEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Schedules & Focus',
      onRefresh: controller.load,
      body: HavenPageBody(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final status = controller.statusMessage.value;
          final error = controller.errorMessage.value;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: HavenSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (status != null) ...[
                  _BannerNotice(message: status, isError: false),
                  const SizedBox(height: HavenSpacing.sm),
                ],
                if (error != null) ...[
                  _BannerNotice(message: error, isError: true),
                  const SizedBox(height: HavenSpacing.sm),
                ],
                _ScheduleSection(
                  title: 'Bedtime Schedules',
                  subtitle: 'Lock device overnight to support healthy sleep habits',
                  schedules: controller.bedtimeSchedules,
                  onAdd: () => _openDialog(context, PolicyScheduleType.bedtime),
                  controller: controller,
                ),
                const SizedBox(height: HavenSpacing.md),
                _ScheduleSection(
                  title: 'School Hours',
                  subtitle: 'Restrict games & social apps during classes; allow school apps',
                  schedules: controller.schoolSchedules,
                  onAdd: () => _openDialog(context, PolicyScheduleType.school),
                  controller: controller,
                ),
                const SizedBox(height: HavenSpacing.md),
                _ScheduleSection(
                  title: 'Custom Focus & Downtime',
                  subtitle: 'Homework sessions, family dinner windows, or screen-free time',
                  schedules: controller.customSchedules,
                  onAdd: () => _openDialog(context, PolicyScheduleType.custom),
                  controller: controller,
                ),
                const SizedBox(height: HavenSpacing.lg),
                HavenButton(
                  label: '+ Create Custom Schedule',
                  primary: false,
                  onPressed: () => _openDialog(context, PolicyScheduleType.custom),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _openDialog(BuildContext context, PolicyScheduleType type, {PolicySchedule? existing}) {
    final sched = existing ?? controller.createDraft(type);
    ScheduleFormDialog.show(context, controller: controller, schedule: sched);
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({
    required this.title,
    required this.subtitle,
    required this.schedules,
    required this.onAdd,
    required this.controller,
  });

  final String title;
  final String subtitle;
  final List<PolicySchedule> schedules;
  final VoidCallback onAdd;
  final SchedulesEditorController controller;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      subtitle: subtitle,
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        tooltip: 'Add',
        onPressed: onAdd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (schedules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: HavenSpacing.sm),
              child: Text('No schedule configured in this section.', style: HavenText.caption),
            )
          else
            for (final sched in schedules)
              ScheduleCardItem(
                schedule: sched,
                onToggle: () => controller.toggleSchedule(sched.id),
                onEdit: () => ScheduleFormDialog.show(context, controller: controller, schedule: sched),
                onDelete: () => controller.deleteSchedule(sched.id),
              ),
        ],
      ),
    );
  }
}

class _BannerNotice extends StatelessWidget {
  const _BannerNotice({required this.message, required this.isError});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(HavenSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(message, style: TextStyle(color: isError ? Colors.red.shade900 : Colors.brown)),
    );
  }
}
