import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../data/help_models.dart';
import '../data/help_repository.dart';

final class HelpController extends GetxController {
  HelpController({
    required HelpRepository repository,
    void Function(String route)? push,
  })  : _repository = repository,
        _push = push ?? ((r) => Get.toNamed(r));

  final HelpRepository _repository;
  final void Function(String route) _push;

  final RxString searchQuery = ''.obs;
  final Rxn<HelpCategory> selectedCategory = Rxn<HelpCategory>();
  final RxList<HelpArticle> articles = <HelpArticle>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshArticles();
  }

  void refreshArticles() {
    final list = _repository.getArticles(
      query: searchQuery.value,
      category: selectedCategory.value,
    );
    articles.assignAll(list);
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    refreshArticles();
  }

  void onCategorySelected(HelpCategory? category) {
    if (selectedCategory.value == category) {
      selectedCategory.value = null;
    } else {
      selectedCategory.value = category;
    }
    refreshArticles();
  }

  void goToFaq() => _push(AppRoutes.faq);
  void goToSupport() => _push(AppRoutes.contactSupport);
}
