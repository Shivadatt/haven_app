import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../shared/components/haven_button.dart';
import '../../../../shared/components/haven_field.dart';
import '../../../../shared/components/haven_scaffold.dart';
import '../../../../shared/components/section_card.dart';
import '../../../../shared/components/status_chip.dart';
import '../../controllers/support_controller.dart';
import '../widgets/ticket_history_card.dart';

class ContactSupportPage extends GetView<SupportController> {
  const ContactSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Contact Support',
      onRefresh: controller.load,
      body: HavenPageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: HavenSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _OfflineBanner(),
              const SizedBox(height: HavenSpacing.md),
              Obx(() => _SupportForm(controller: controller)),
              const SizedBox(height: HavenSpacing.lg),
              Obx(() => TicketHistoryCard(tickets: controller.tickets)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'Offline Support Seam',
      trailing: StatusChip(label: 'Offline Active', tone: StatusTone.good),
      child: Text(
        'Haven operates with an offline-first architecture. Any support '
        'ticket or issue logged is safely persisted to your local audit '
        'tables and can be reviewed or exported at any time.',
        style: HavenText.body,
      ),
    );
  }
}

class _SupportForm extends StatelessWidget {
  const _SupportForm({required this.controller});
  final SupportController controller;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Create Support Inquiry',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HavenField(
            label: 'Subject',
            controller: controller.subjectController,
            helper: controller.subjectError.value ?? 'Brief summary of the issue',
          ),
          const SizedBox(height: HavenSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: controller.selectedCategory.value,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: SupportController.categories.map((c) {
              return DropdownMenuItem(value: c, child: Text(c, style: HavenText.body));
            }).toList(),
            onChanged: (val) {
              if (val != null) controller.selectedCategory.value = val;
            },
          ),
          const SizedBox(height: HavenSpacing.md),
          TextFormField(
            controller: controller.descriptionController,
            maxLines: 4,
            style: HavenText.body,
            decoration: InputDecoration(
              labelText: 'Description',
              helperText: controller.descriptionError.value ??
                  'Please provide details on what happened or what you need',
              border: const OutlineInputBorder(),
            ),
          ),
          if (controller.statusMessage.value != null) ...[
            const SizedBox(height: HavenSpacing.sm),
            Text(
              controller.statusMessage.value!,
              style: HavenText.caption,
            ),
          ],
          const SizedBox(height: HavenSpacing.lg),
          Row(
            children: [
              Expanded(
                child: HavenButton(
                  label: 'Save Draft',
                  primary: false,
                  onPressed: controller.saveDraft,
                ),
              ),
              const SizedBox(width: HavenSpacing.md),
              Expanded(
                child: HavenButton(
                  label: 'Submit Ticket',
                  busy: controller.isSubmitting.value,
                  onPressed: controller.submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
