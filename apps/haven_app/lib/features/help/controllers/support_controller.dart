import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/help_models.dart';
import '../data/help_repository.dart';

final class SupportController extends GetxController {
  SupportController({required HelpRepository repository})
      : _repository = repository;

  final HelpRepository _repository;

  final TextEditingController subjectController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final RxString selectedCategory = 'General Inquiry'.obs;

  final RxnString subjectError = RxnString();
  final RxnString descriptionError = RxnString();
  final RxnString statusMessage = RxnString();
  final RxBool isSubmitting = false.obs;

  final RxList<SupportTicket> tickets = <SupportTicket>[].obs;

  static const List<String> categories = [
    'General Inquiry',
    'Account & Sign-In',
    'Device Pairing & Sync',
    'Policies & Limits',
    'Location & Safe Zones',
    'Feature Suggestion',
  ];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    subjectController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    final res = await _repository.loadTickets();
    if (res.isOk) {
      tickets.assignAll(res.valueOrNull ?? []);
    }
    final draftRes = await _repository.loadDraft();
    final draft = draftRes.valueOrNull;
    if (draft != null) {
      subjectController.text = draft.subject;
      descriptionController.text = draft.description;
      selectedCategory.value = draft.category;
    }
  }

  bool validate() {
    bool valid = true;
    final subject = subjectController.text.trim();
    final description = descriptionController.text.trim();

    if (subject.isEmpty) {
      subjectError.value = 'Please enter a subject';
      valid = false;
    } else if (subject.length < 3) {
      subjectError.value = 'Subject must be at least 3 characters';
      valid = false;
    } else {
      subjectError.value = null;
    }

    if (description.isEmpty) {
      descriptionError.value = 'Please describe your request or issue';
      valid = false;
    } else if (description.length < 10) {
      descriptionError.value = 'Description must be at least 10 characters';
      valid = false;
    } else {
      descriptionError.value = null;
    }

    return valid;
  }

  Future<bool> submit() async {
    if (!validate()) return false;
    isSubmitting.value = true;
    statusMessage.value = null;

    final ticket = SupportTicket(
      id: '',
      subject: subjectController.text.trim(),
      category: selectedCategory.value,
      description: descriptionController.text.trim(),
      createdAt: DateTime.now(),
    );

    final res = await _repository.submitTicket(ticket);
    isSubmitting.value = false;

    if (res.isOk) {
      statusMessage.value = 'Support ticket saved locally!';
      subjectController.clear();
      descriptionController.clear();
      await load();
      return true;
    } else {
      statusMessage.value = res.failureOrNull?.message;
      return false;
    }
  }

  Future<void> saveDraft() async {
    final ticket = SupportTicket(
      id: 'draft',
      subject: subjectController.text.trim(),
      category: selectedCategory.value,
      description: descriptionController.text.trim(),
      createdAt: DateTime.now(),
      isDraft: true,
    );
    await _repository.saveDraft(ticket);
    statusMessage.value = 'Draft saved locally.';
  }
}
