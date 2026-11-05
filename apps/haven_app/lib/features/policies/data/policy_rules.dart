/// Validation helpers and format checkers for app and website policies.
abstract final class PolicyRules {
  /// Validates a domain name according to standard DNS hostname rules.
  /// Rejects protocol prefixes (http://, https://), paths (/), and invalid characters.
  static bool isValidDomain(String input) {
    final clean = input.trim().toLowerCase();
    if (clean.isEmpty || clean.length > 253) return false;
    if (clean.contains('://') || clean.contains('/')) return false;
    // Must contain at least one dot, no leading/trailing dot or hyphen
    final domainRegex = RegExp(
      r'^(?!-)[a-z0-9-]{1,63}(?<!-)(\.[a-z0-9-]{1,63}(?<!-))*\.[a-z]{2,}$',
    );
    return domainRegex.hasMatch(clean);
  }

  /// Returns null if valid, or a descriptive user error string if invalid.
  static String? validateDomain(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Domain cannot be empty.';
    }
    final clean = input.trim();
    if (clean.contains('://')) {
      return 'Do not include http:// or https:// in the domain.';
    }
    if (clean.contains('/')) {
      return 'Do not include url paths or trailing slashes.';
    }
    if (!isValidDomain(clean)) {
      return 'Enter a valid domain name (e.g. example.com or sub.example.org).';
    }
    return null;
  }

  /// Validates an Android application package name or identifier.
  static String? validatePackageName(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Package name cannot be empty.';
    }
    final clean = input.trim();
    if (clean.length < 3) {
      return 'Package name is too short.';
    }
    final packageRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$');
    if (!packageRegex.hasMatch(clean)) {
      return 'Enter a valid package name (e.g. com.example.app).';
    }
    return null;
  }

  /// Validates a daily or per-app limit in minutes.
  static String? validateMinutesLimit(int? minutes, {int max = 1440}) {
    if (minutes == null) return 'Limit is required.';
    if (minutes < 0 || minutes > max) {
      return 'Limit must be between 0 and $max minutes.';
    }
    return null;
  }
}
