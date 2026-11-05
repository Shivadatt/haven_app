import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/policies/data/web_filter_models.dart';

void main() {
  group('WebFilterModels', () {
    test('normalizes URLs into clean domain hostnames', () {
      expect(
        WebFilterModels.normalizeDomain('https://www.youtube.com/watch?v=123'),
        'www.youtube.com',
      );
      expect(
        WebFilterModels.normalizeDomain('http://example.com:8080/path/test#frag'),
        'example.com',
      );
      expect(
        WebFilterModels.normalizeDomain('   GAMBLING.COM/bet/live  '),
        'gambling.com',
      );
    });

    test('categorizes domains according to presets', () {
      expect(
        WebFilterModels.categorize('pornhub.com'),
        WebCategory.adult,
      );
      expect(
        WebFilterModels.categorize('bet365.com'),
        WebCategory.gambling,
      );
      expect(
        WebFilterModels.categorize('tiktok.com'),
        WebCategory.social,
      );
      expect(
        WebFilterModels.categorize('roblox.com'),
        WebCategory.gaming,
      );
      expect(
        WebFilterModels.categorize('wikipedia.org'),
        WebCategory.education,
      );
      expect(
        WebFilterModels.categorize('mycustomdomain.org'),
        WebCategory.custom,
      );
    });

    test('presets contain expected categories', () {
      expect(WebFilterModels.presets.containsKey(WebCategory.adult), isTrue);
      expect(WebFilterModels.presets.containsKey(WebCategory.gambling), isTrue);
      expect(WebFilterModels.presets.containsKey(WebCategory.social), isTrue);
      expect(WebFilterModels.presets.containsKey(WebCategory.gaming), isTrue);
    });
  });
}
