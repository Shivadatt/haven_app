import 'help_models.dart';

final class HelpContent {
  static const List<HelpArticle> articles = [
    HelpArticle(
      id: 'art_1',
      title: 'Quick Start: Setting Up Haven',
      category: HelpCategory.gettingStarted,
      summary: 'Learn how to set up your parent account and link child devices.',
      content:
          '1. Set up your parental profile and verify your account.\n'
          '2. Go to Family > Add Child and create a profile.\n'
          '3. Generate a pairing code on your phone and enter it on your child\'s device.\n'
          '4. Once paired, Haven establishes a secure local control channel.',
    ),
    HelpArticle(
      id: 'art_2',
      title: 'Configuring Daily Screen Time Limits',
      category: HelpCategory.policies,
      summary: 'Enforce balanced screen time and quiet hours for your child.',
      content:
          'Set a daily total screen time budget (e.g. 120 minutes).\n'
          'When the limit is reached, Haven blocks non-exempt apps.\n'
          'Children can send an extension request which parents can approve or reject in real time.',
    ),
    HelpArticle(
      id: 'art_3',
      title: 'Managing App Rules & Web Filters',
      category: HelpCategory.policies,
      summary: 'Allow, restrict, or block specific apps and websites.',
      content:
          'Define individual app limits or restrict app categories such as Games or Social Media.\n'
          'Use the web filter to block unsafe domains or restrict browsing to an approved list of educational sites.',
    ),
    HelpArticle(
      id: 'art_4',
      title: 'Safe Zones & Geofencing Alerts',
      category: HelpCategory.location,
      summary: 'Create geofences around Home, School, and other familiar places.',
      content:
          'Safe zones notify you when your child arrives at or departs a defined boundary.\n'
          'Location readings respect privacy and are stored directly on-device in local tables.',
    ),
    HelpArticle(
      id: 'art_5',
      title: 'Offline Operation & Privacy Guarantees',
      category: HelpCategory.offline,
      summary: 'How Haven protects your family data without cloud tracking.',
      content:
          'Haven operates with strict zero-knowledge architecture.\n'
          'In offline mode, data is held in local encrypted vault tables and no third-party servers receive child telemetry.',
    ),
  ];

  static const List<FaqItem> faqs = [
    FaqItem(
      id: 'faq_1',
      question: 'Does Haven hide itself on my child\'s phone?',
      answer:
          'No. Haven is completely transparent. The app is visible on the child\'s phone with clear indicators of active parental controls.',
      category: HelpCategory.gettingStarted,
    ),
    FaqItem(
      id: 'faq_2',
      question: 'How do screen-time extensions work?',
      answer:
          'When time runs out, a child can tap "Request Extension" with an optional note. The parent receives an alert in the Approvals queue and can approve +15, +30, +60 minutes or a custom amount.',
      category: HelpCategory.policies,
    ),
    FaqItem(
      id: 'faq_3',
      question: 'What happens when my phone is offline?',
      answer:
          'Haven works seamlessly in offline mode. All settings, rules, approvals, and support tickets are cached in local tables and immediately active on device.',
      category: HelpCategory.offline,
    ),
    FaqItem(
      id: 'faq_4',
      question: 'Can I block specific apps while allowing educational apps?',
      answer:
          'Yes! In App Rules, you can allowlist specific apps (like Duolingo or Classroom) while putting strict limits on games and social media.',
      category: HelpCategory.policies,
    ),
    FaqItem(
      id: 'faq_5',
      question: 'How do I unpair or transfer a device?',
      answer:
          'Go to Devices > Select Device > Settings, and tap "Unlink Device". All local policy bindings will be securely cleared.',
      category: HelpCategory.pairing,
    ),
  ];
}
