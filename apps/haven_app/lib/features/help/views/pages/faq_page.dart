import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../shared/components/haven_scaffold.dart';
import '../../../../shared/components/section_card.dart';
import '../../controllers/faq_controller.dart';
import '../../data/help_models.dart';

class FaqPage extends GetView<FaqController> {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Frequently Asked Questions',
      body: HavenPageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: HavenSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search questions...',
                  border: OutlineInputBorder(),
                ),
                onChanged: controller.onSearchChanged,
              ),
              const SizedBox(height: HavenSpacing.md),
              _FaqCategoryFilters(controller: controller),
              const SizedBox(height: HavenSpacing.lg),
              Obx(() {
                final list = controller.faqs;
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(HavenSpacing.xl),
                    child: Center(
                      child: Text('No FAQs match your search.',
                          style: HavenText.caption),
                    ),
                  );
                }
                return Column(
                  children: list.map((faq) => _FaqTile(faq: faq)).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqCategoryFilters extends StatelessWidget {
  const _FaqCategoryFilters({required this.controller});
  final FaqController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedCategory.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: HelpCategory.values.map((cat) {
            final isSelected = selected == cat;
            return Padding(
              padding: const EdgeInsets.only(right: HavenSpacing.xs),
              child: FilterChip(
                label: Text(cat.label),
                selected: isSelected,
                onSelected: (_) => controller.onCategorySelected(cat),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.faq});
  final FaqItem faq;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HavenSpacing.sm),
      child: SectionCard(
        title: faq.question,
        subtitle: faq.category.label,
        child: Text(faq.answer, style: HavenText.body),
      ),
    );
  }
}
