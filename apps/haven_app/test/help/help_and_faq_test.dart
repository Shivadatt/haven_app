import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/features/help/controllers/faq_controller.dart';
import 'package:haven_app/features/help/controllers/help_controller.dart';
import 'package:haven_app/features/help/data/help_models.dart';
import 'package:haven_app/features/help/data/local_support_repository.dart';

void main() {
  late LocalSupportRepository repo;
  late HelpController helpController;
  late FaqController faqController;

  setUp(() {
    Get.reset();
    repo = LocalSupportRepository();
    helpController = HelpController(repository: repo);
    faqController = FaqController(repository: repo);
  });

  tearDown(Get.reset);

  test('loads all help articles initially', () {
    helpController.refreshArticles();
    expect(helpController.articles, isNotEmpty);
  });

  test('filters help articles by search query', () {
    helpController.onSearchChanged('geofencing');
    expect(helpController.articles, isNotEmpty);
    expect(
      helpController.articles.every((a) =>
          a.title.toLowerCase().contains('geofencing') ||
          a.content.toLowerCase().contains('geofencing') ||
          a.summary.toLowerCase().contains('geofencing')),
      isTrue,
    );

    // Non-matching search yields empty list
    helpController.onSearchChanged('nonexistentkeyword12345');
    expect(helpController.articles, isEmpty);
  });

  test('filters help articles by category', () {
    helpController.onCategorySelected(HelpCategory.policies);
    expect(helpController.articles, isNotEmpty);
    expect(
      helpController.articles.every((a) => a.category == HelpCategory.policies),
      isTrue,
    );

    // Unselecting resets
    helpController.onCategorySelected(HelpCategory.policies);
    expect(helpController.selectedCategory.value, isNull);
  });

  test('loads and filters FAQs by search query and category', () {
    faqController.refreshFaqs();
    expect(faqController.faqs, isNotEmpty);

    faqController.onSearchChanged('screen-time');
    expect(faqController.faqs, isNotEmpty);

    faqController.onCategorySelected(HelpCategory.gettingStarted);
    expect(
      faqController.faqs.every((f) => f.category == HelpCategory.gettingStarted),
      isTrue,
    );
  });
}
