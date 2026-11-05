import 'package:flutter/material.dart';

enum WebCategory {
  all('All', Icons.public_rounded),
  adult('Adult', Icons.explicit_rounded),
  gambling('Gambling', Icons.casino_outlined),
  social('Social', Icons.people_outline_rounded),
  gaming('Gaming', Icons.sports_esports_outlined),
  education('Education', Icons.school_outlined),
  custom('Custom', Icons.tune_rounded);

  const WebCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

final class WebFilterModels {
  static const Map<WebCategory, List<String>> presets = {
    WebCategory.adult: [
      'pornhub.com',
      'xvideos.com',
      'onlyfans.com',
      'chaturbate.com',
    ],
    WebCategory.gambling: [
      'bet365.com',
      'gambling.com',
      'pokerstars.com',
      'draftkings.com',
    ],
    WebCategory.social: [
      'tiktok.com',
      'instagram.com',
      'reddit.com',
      'twitter.com',
      'snapchat.com',
    ],
    WebCategory.gaming: [
      'roblox.com',
      'twitch.tv',
      'steampowered.com',
      'epicgames.com',
    ],
    WebCategory.education: [
      'wikipedia.org',
      'khanacademy.org',
      'coursera.org',
      'edx.org',
    ],
  };

  static WebCategory categorize(String domain) {
    final clean = domain.toLowerCase();
    for (final entry in presets.entries) {
      if (entry.value.any((p) => clean == p || clean.endsWith('.$p'))) {
        return entry.key;
      }
    }
    return WebCategory.custom;
  }

  /// Normalizes user input into a clean hostname:
  /// - trims whitespace
  /// - removes leading protocol (http://, https://)
  /// - strips port (:8080)
  /// - strips path and query parameters (/...)
  /// - converts to lowercase
  static String normalizeDomain(String raw) {
    var clean = raw.trim().toLowerCase();
    if (clean.contains('://')) {
      final idx = clean.indexOf('://');
      clean = clean.substring(idx + 3);
    }
    if (clean.contains('/')) {
      clean = clean.split('/').first;
    }
    if (clean.contains('?')) {
      clean = clean.split('?').first;
    }
    if (clean.contains('#')) {
      clean = clean.split('#').first;
    }
    if (clean.contains(':')) {
      clean = clean.split(':').first;
    }
    return clean.trim();
  }
}
