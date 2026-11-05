enum HelpCategory {
  gettingStarted('Getting Started'),
  policies('Policies & Limits'),
  location('Safe Zones & Location'),
  pairing('Device Pairing'),
  offline('Offline & Security');

  const HelpCategory(this.label);
  final String label;
}

final class HelpArticle {
  const HelpArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.content,
  });

  final String id;
  final String title;
  final HelpCategory category;
  final String summary;
  final String content;
}

final class FaqItem {
  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
  });

  final String id;
  final String question;
  final String answer;
  final HelpCategory category;
}

final class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.category,
    required this.description,
    required this.createdAt,
    this.isDraft = false,
  });

  final String id;
  final String subject;
  final String category;
  final String description;
  final DateTime createdAt;
  final bool isDraft;

  Map<String, Object?> toJson() => {
        'id': id,
        'subject': subject,
        'category': category,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'is_draft': isDraft,
      };

  factory SupportTicket.fromJson(Map<String, Object?> json) => SupportTicket(
        id: json['id'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        description: json['description'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        isDraft: json['is_draft'] as bool? ?? false,
      );
}
