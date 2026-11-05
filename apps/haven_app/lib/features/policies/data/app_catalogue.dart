import 'package:flutter/material.dart';

enum AppCategory {
  all('All', Icons.apps_rounded),
  social('Social', Icons.people_outline_rounded),
  games('Games', Icons.sports_esports_outlined),
  entertainment('Entertainment', Icons.movie_outlined),
  education('Education', Icons.school_outlined),
  utilities('Utilities', Icons.build_outlined);

  const AppCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

final class AppCatalogueItem {
  const AppCatalogueItem({
    required this.name,
    required this.packageName,
    required this.category,
    this.icon = Icons.android_rounded,
  });

  final String name;
  final String packageName;
  final AppCategory category;
  final IconData icon;
}

abstract final class AppCatalogue {
  static const List<AppCatalogueItem> catalogue = [
    AppCatalogueItem(
      name: 'YouTube',
      packageName: 'com.google.android.youtube',
      category: AppCategory.entertainment,
      icon: Icons.play_circle_outline_rounded,
    ),
    AppCatalogueItem(
      name: 'TikTok',
      packageName: 'com.zhiliaoapp.musically',
      category: AppCategory.social,
      icon: Icons.music_note_rounded,
    ),
    AppCatalogueItem(
      name: 'Roblox',
      packageName: 'com.roblox.client',
      category: AppCategory.games,
      icon: Icons.games_rounded,
    ),
    AppCatalogueItem(
      name: 'Google Chrome',
      packageName: 'com.android.chrome',
      category: AppCategory.utilities,
      icon: Icons.public_rounded,
    ),
    AppCatalogueItem(
      name: 'Instagram',
      packageName: 'com.instagram.android',
      category: AppCategory.social,
      icon: Icons.camera_alt_outlined,
    ),
    AppCatalogueItem(
      name: 'Minecraft',
      packageName: 'com.mojang.minecraftpe',
      category: AppCategory.games,
      icon: Icons.videogame_asset_outlined,
    ),
    AppCatalogueItem(
      name: 'Discord',
      packageName: 'com.discord',
      category: AppCategory.social,
      icon: Icons.chat_bubble_outline_rounded,
    ),
    AppCatalogueItem(
      name: 'Netflix',
      packageName: 'com.netflix.mediaclient',
      category: AppCategory.entertainment,
      icon: Icons.tv_rounded,
    ),
    AppCatalogueItem(
      name: 'Duolingo',
      packageName: 'com.duolingo',
      category: AppCategory.education,
      icon: Icons.language_rounded,
    ),
    AppCatalogueItem(
      name: 'Khan Academy',
      packageName: 'org.khanacademy.android',
      category: AppCategory.education,
      icon: Icons.school_rounded,
    ),
    AppCatalogueItem(
      name: 'Spotify',
      packageName: 'com.spotify.music',
      category: AppCategory.entertainment,
      icon: Icons.headphones_rounded,
    ),
    AppCatalogueItem(
      name: 'Calculator',
      packageName: 'com.android.calculator2',
      category: AppCategory.utilities,
      icon: Icons.calculate_outlined,
    ),
    AppCatalogueItem(
      name: 'Google Docs',
      packageName: 'com.google.android.apps.docs',
      category: AppCategory.education,
      icon: Icons.description_outlined,
    ),
    AppCatalogueItem(
      name: 'Snapchat',
      packageName: 'com.snapchat.android',
      category: AppCategory.social,
      icon: Icons.chat_outlined,
    ),
  ];

  static AppCatalogueItem lookup(String packageName) {
    for (final item in catalogue) {
      if (item.packageName == packageName) return item;
    }
    final nameParts = packageName.split('.');
    final fallbackName = nameParts.isNotEmpty
        ? nameParts.last[0].toUpperCase() + nameParts.last.substring(1)
        : packageName;
    return AppCatalogueItem(
      name: fallbackName,
      packageName: packageName,
      category: AppCategory.utilities,
    );
  }
}
