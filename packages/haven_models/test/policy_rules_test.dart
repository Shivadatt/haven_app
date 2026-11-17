import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

void main() {
  group('PolicyRules', () {
    test('isValidDomain accepts valid DNS hostnames', () {
      expect(PolicyRules.isValidDomain('example.com'), isTrue);
      expect(PolicyRules.isValidDomain('sub.domain.org'), isTrue);
      expect(PolicyRules.isValidDomain('a-b.co.uk'), isTrue);
    });

    test('isValidDomain rejects protocols, paths, and malformed names', () {
      expect(PolicyRules.isValidDomain('http://example.com'), isFalse);
      expect(PolicyRules.isValidDomain('https://example.com'), isFalse);
      expect(PolicyRules.isValidDomain('example.com/path'), isFalse);
      expect(PolicyRules.isValidDomain('example'), isFalse);
      expect(PolicyRules.isValidDomain('-bad.com'), isFalse);
      expect(PolicyRules.isValidDomain(''), isFalse);
    });

    test('validateDomain returns null for valid or clear error message', () {
      expect(PolicyRules.validateDomain('example.com'), isNull);
      expect(PolicyRules.validateDomain(''), 'Domain cannot be empty.');
      expect(
        PolicyRules.validateDomain('http://example.com'),
        'Do not include http:// or https:// in the domain.',
      );
      expect(
        PolicyRules.validateDomain('example.com/test'),
        'Do not include url paths or trailing slashes.',
      );
      expect(
        PolicyRules.validateDomain('invalid_domain'),
        'Enter a valid domain name (e.g. example.com or sub.example.org).',
      );
    });

    test('validatePackageName enforces Android package identifier rules', () {
      expect(PolicyRules.validatePackageName('com.example.app'), isNull);
      expect(PolicyRules.validatePackageName('org.haven.child_app'), isNull);
      expect(PolicyRules.validatePackageName(''), 'Package name cannot be empty.');
      expect(PolicyRules.validatePackageName('ab'), 'Package name is too short.');
      expect(
        PolicyRules.validatePackageName('1com.invalid.pkg'),
        'Enter a valid package name (e.g. com.example.app).',
      );
      expect(
        PolicyRules.validatePackageName('no_dots_package'),
        'Enter a valid package name (e.g. com.example.app).',
      );
    });

    test('validateMinutesLimit bounds check', () {
      expect(PolicyRules.validateMinutesLimit(120), isNull);
      expect(PolicyRules.validateMinutesLimit(0), isNull);
      expect(PolicyRules.validateMinutesLimit(1440), isNull);
      expect(PolicyRules.validateMinutesLimit(null), 'Limit is required.');
      expect(PolicyRules.validateMinutesLimit(-1), 'Limit must be between 0 and 1440 minutes.');
      expect(PolicyRules.validateMinutesLimit(1441), 'Limit must be between 0 and 1440 minutes.');
      expect(
        PolicyRules.validateMinutesLimit(60, max: 30),
        'Limit must be between 0 and 30 minutes.',
      );
    });
  });
}
