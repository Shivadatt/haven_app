import 'package:haven_core/haven_core.dart';
import 'help_models.dart';

abstract interface class HelpRepository {
  List<HelpArticle> getArticles({String? query, HelpCategory? category});

  List<FaqItem> getFaqs({String? query, HelpCategory? category});

  Future<Result<List<SupportTicket>>> loadTickets();

  Future<Result<void>> submitTicket(SupportTicket ticket);

  Future<Result<void>> saveDraft(SupportTicket ticket);

  Future<Result<SupportTicket?>> loadDraft();
}
