import 'package:flutter/material.dart';
import '../../../../app/theme/haven_spacing.dart';
import '../../../../app/theme/haven_text.dart';
import '../../../../shared/components/haven_button.dart';
import '../../data/help_models.dart';

class HelpArticleDialog extends StatelessWidget {
  const HelpArticleDialog({super.key, required this.article});

  final HelpArticle article;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(article.title, style: HavenText.headline),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(label: Text(article.category.label, style: HavenText.caption)),
            const SizedBox(height: HavenSpacing.md),
            Text(article.content, style: HavenText.body),
          ],
        ),
      ),
      actions: [
        HavenButton(
          label: 'Close',
          primary: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
