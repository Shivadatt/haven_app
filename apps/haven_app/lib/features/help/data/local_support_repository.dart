import 'dart:convert';
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'help_content.dart';
import 'help_models.dart';
import 'help_repository.dart';

final class LocalSupportRepository implements HelpRepository {
  LocalSupportRepository({LocalTables? tables}) : _tables = tables;

  final LocalTables? _tables;
  LocalTables? get _activeTables =>
      _tables ?? (Get.isRegistered<LocalTables>() ? Get.find<LocalTables>() : null);

  final List<SupportTicket> _tickets = [];
  SupportTicket? _draft;

  @override
  List<HelpArticle> getArticles({String? query, HelpCategory? category}) {
    return HelpContent.articles.where((art) {
      final matchesCat = category == null || art.category == category;
      if (!matchesCat) return false;
      if (query == null || query.trim().isEmpty) return true;
      final q = query.trim().toLowerCase();
      return art.title.toLowerCase().contains(q) ||
          art.summary.toLowerCase().contains(q) ||
          art.content.toLowerCase().contains(q);
    }).toList();
  }

  @override
  List<FaqItem> getFaqs({String? query, HelpCategory? category}) {
    return HelpContent.faqs.where((faq) {
      final matchesCat = category == null || faq.category == category;
      if (!matchesCat) return false;
      if (query == null || query.trim().isEmpty) return true;
      final q = query.trim().toLowerCase();
      return faq.question.toLowerCase().contains(q) ||
          faq.answer.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<Result<List<SupportTicket>>> loadTickets() async {
    return Ok([..._tickets]);
  }

  @override
  Future<Result<void>> submitTicket(SupportTicket ticket) async {
    final entry = SupportTicket(
      id: ticket.id.isNotEmpty ? ticket.id : LocalIds.create(),
      subject: ticket.subject,
      category: ticket.category,
      description: ticket.description,
      createdAt: DateTime.now(),
      isDraft: false,
    );
    _tickets.insert(0, entry);
    _draft = null;

    final tables = _activeTables;
    if (tables != null) {
      await tables.insert(TableName.auditLogs, <String, Object?>{
        'id': LocalIds.create(),
        'family_id': 'support_logs',
        'device_id': 'local_user',
        'action': 'support_ticket_created',
        'detail': jsonEncode(entry.toJson()),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    }

    return okVoid();
  }

  @override
  Future<Result<void>> saveDraft(SupportTicket ticket) async {
    _draft = ticket;
    return okVoid();
  }

  @override
  Future<Result<SupportTicket?>> loadDraft() async {
    return Ok(_draft);
  }
}
