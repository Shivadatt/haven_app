import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/policies/data/app_catalogue.dart';

void main() {
  group('AppCatalogue', () {
    test('contains curated popular applications with proper categories', () {
      expect(AppCatalogue.catalogue.isNotEmpty, isTrue);

      final yt = AppCatalogue.lookup('com.google.android.youtube');
      expect(yt.name, 'YouTube');
      expect(yt.category, AppCategory.entertainment);

      final tiktok = AppCatalogue.lookup('com.zhiliaoapp.musically');
      expect(tiktok.name, 'TikTok');
      expect(tiktok.category, AppCategory.social);

      final roblox = AppCatalogue.lookup('com.roblox.client');
      expect(roblox.name, 'Roblox');
      expect(roblox.category, AppCategory.games);

      final chrome = AppCatalogue.lookup('com.android.chrome');
      expect(chrome.name, 'Google Chrome');
      expect(chrome.category, AppCategory.utilities);
    });

    test('generates fallback name for unknown package name', () {
      final unknown = AppCatalogue.lookup('com.example.mathapp');
      expect(unknown.packageName, 'com.example.mathapp');
      expect(unknown.name, 'Mathapp');
      expect(unknown.category, AppCategory.utilities);
    });
  });
}
