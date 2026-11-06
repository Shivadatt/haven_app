import 'package:flutter/material.dart';

/// The child's avatar choices — Material icons only (brief §4 C: "no asset
/// files"). The stored value is the [name]; `Icons.*` never goes into the
/// database, so a later icon change cannot corrupt old rows: [resolve]
/// degrades to a neutral icon for unknown names instead of failing.
final class ChildAvatarOption {
  const ChildAvatarOption({required this.name, required this.icon});

  final String name;
  final IconData icon;
}

abstract final class ChildAvatars {
  static const List<ChildAvatarOption> options = <ChildAvatarOption>[
    ChildAvatarOption(name: 'person', icon: Icons.person),
    ChildAvatarOption(name: 'rocket', icon: Icons.rocket_launch),
    ChildAvatarOption(name: 'panda', icon: Icons.pets),
    ChildAvatarOption(name: 'star', icon: Icons.star),
    ChildAvatarOption(name: 'bike', icon: Icons.directions_bike),
    ChildAvatarOption(name: 'music', icon: Icons.music_note),
    ChildAvatarOption(name: 'game', icon: Icons.sports_esports),
    ChildAvatarOption(name: 'book', icon: Icons.menu_book),
  ];

  static const ChildAvatarOption fallback = ChildAvatarOption(
    name: 'person',
    icon: Icons.person_outline,
  );

  static ChildAvatarOption resolve(String? name) {
    for (final option in options) {
      if (option.name == name) return option;
    }
    return fallback;
  }
}
