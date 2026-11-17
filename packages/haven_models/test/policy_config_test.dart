import 'package:haven_models/haven_models.dart';
import 'package:test/test.dart';

void main() {
  group('PolicyConfig', () {
    test('defaults() produces expected default configuration', () {
      final config = PolicyConfig.defaults();
      expect(config.dailyScreenTimeMinutes, 120);
      expect(config.schedules.length, 2);
      expect(config.allowedApps, contains('com.android.calculator2'));
      expect(config.blockedApps, contains('com.zhiliaoapp.musically'));
      expect(config.appLimits['com.google.android.youtube'], 30);
      expect(config.allowedDomains, contains('wikipedia.org'));
      expect(config.blockedDomains, contains('tiktok.com'));
      expect(config.safeSearchEnabled, isTrue);
    });

    test('toJson and fromJson round-trip perfectly', () {
      final original = PolicyConfig.defaults();
      final json = original.toJson();
      final parsed = PolicyConfig.fromJson(json);

      expect(parsed.dailyScreenTimeMinutes, original.dailyScreenTimeMinutes);
      expect(parsed.schedules.length, original.schedules.length);
      expect(parsed.allowedApps, original.allowedApps);
      expect(parsed.blockedApps, original.blockedApps);
      expect(parsed.appLimits, original.appLimits);
      expect(parsed.allowedDomains, original.allowedDomains);
      expect(parsed.blockedDomains, original.blockedDomains);
      expect(parsed.safeSearchEnabled, original.safeSearchEnabled);
    });

    test('fromJson falls back gracefully on empty or missing fields', () {
      final parsed = PolicyConfig.fromJson(const {});
      expect(parsed.dailyScreenTimeMinutes, 120);
      expect(parsed.schedules.length, 2);
      expect(parsed.allowedApps, isEmpty);
      expect(parsed.blockedApps, isEmpty);
      expect(parsed.appLimits, isEmpty);
      expect(parsed.allowedDomains, isEmpty);
      expect(parsed.blockedDomains, isEmpty);
      expect(parsed.safeSearchEnabled, isTrue);
    });

    test('copyWith updates fields without mutating original', () {
      final original = PolicyConfig.defaults();
      final updated = original.copyWith(
        dailyScreenTimeMinutes: 90,
        safeSearchEnabled: false,
      );

      expect(updated.dailyScreenTimeMinutes, 90);
      expect(updated.safeSearchEnabled, isFalse);
      expect(original.dailyScreenTimeMinutes, 120);
      expect(original.safeSearchEnabled, isTrue);
    });

    test('validate() catches invalid screen time or domain syntax', () {
      final valid = PolicyConfig.defaults();
      expect(valid.validate(), isNull);

      final invalidTime = valid.copyWith(dailyScreenTimeMinutes: -10);
      expect(invalidTime.validate(), contains('between 0 and 1440'));

      final invalidDomain = valid.copyWith(allowedDomains: ['http://invalid.com']);
      expect(invalidDomain.validate(), contains('Do not include http://'));
    });
  });
}
