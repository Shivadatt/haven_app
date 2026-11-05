import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../shared/components/haven_scaffold.dart';
import '../../../../shared/components/section_card.dart';
import '../../controllers/help_controller.dart';
import '../../data/help_models.dart';
import '../widgets/help_article_dialog.dart';

class HelpCenterPage extends GetView<HelpController> {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HavenScaffold(
      title: 'Help Centre',
      body: HavenPageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: HavenSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search help guides & articles...',
                  border: OutlineInputBorder(),
                ),
                onChanged: controller.onSearchChanged,
              ),
              const SizedBox(height: HavenSpacing.md),
              _CategoryFilters(controller: controller),
              const SizedBox(height: HavenSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.quiz_outlined),
                      label: const Text('FAQs'),
                      onPressed: controller.goToFaq,
                    ),
                  ),
                  const SizedBox(width: HavenSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.support_agent_rounded),
                      label: const Text('Contact Support'),
                      onPressed: controller.goToSupport,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HavenSpacing.lg),
              Obx(() {
                final list = controller.articles;
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(HavenSpacing.xl),
                    child: Center(
                      child: Text('No articles found matching your query.',
                          style: HavenText.caption),
                    ),
                  );
                }
                return Column(
                  children: list.map((art) => _ArticleCard(article: art)).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({required this.controller});
  final HelpController controller;

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

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});
  final HelpArticle article;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HavenSpacing.md),
      child: SectionCard(
        title: article.title,
        subtitle: article.category.label,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(article.summary, style: HavenText.body),
            const SizedBox(height: HavenSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Read Article'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => HelpArticleDialog(article: article),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
