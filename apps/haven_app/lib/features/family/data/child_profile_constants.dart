/// Constants and options for child profiles.
abstract final class ChildProfileConstants {
  static const int minNameLength = 1;
  static const int maxNameLength = 60;

  static const List<String> ageBrackets = <String>[
    '4–7',
    '8–11',
    '12–14',
    '15–17',
  ];

  static const List<String> avatars = <String>[
    '🦊',
    '🐻',
    '🦁',
    '🐼',
    '🐨',
    '🐯',
    '🚀',
    '⭐',
  ];

  static String? validateName(String? name) {
    final String trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return 'Enter a name for the child.';
    if (trimmed.length > maxNameLength) {
      return 'Name must be 60 characters or fewer.';
    }
    return null;
  }
}
