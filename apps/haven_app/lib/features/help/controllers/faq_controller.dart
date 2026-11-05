import 'package:get/get.dart';
import '../data/help_models.dart';
import '../data/help_repository.dart';

final class FaqController extends GetxController {
  FaqController({required HelpRepository repository})
      : _repository = repository;

  final HelpRepository _repository;

  final RxString searchQuery = ''.obs;
  final Rxn<HelpCategory> selectedCategory = Rxn<HelpCategory>();
  final RxList<FaqItem> faqs = <FaqItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshFaqs();
  }

  void refreshFaqs() {
    final list = _repository.getFaqs(
      query: searchQuery.value,
      category: selectedCategory.value,
    );
    faqs.assignAll(list);
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    refreshFaqs();
  }

  void onCategorySelected(HelpCategory? category) {
    if (selectedCategory.value == category) {
      selectedCategory.value = null;
    } else {
      selectedCategory.value = category;
    }
    refreshFaqs();
  }
}
