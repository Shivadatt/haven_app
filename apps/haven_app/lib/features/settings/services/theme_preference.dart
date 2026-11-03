import 'package:flutter/material.dart' show ThemeMode;
import 'package:get/get.dart';

import '../data/settings_repository.dart';

/// Applies the stored appearance choice once, before the first screen paints.
///
/// `HavenApp` starts on `ThemeMode.system`; without this service a parent's
/// choice would only take effect after they found the settings screen again,
/// which is the kind of setting that reads as broken.
final class ThemePreference extends GetxService {
  ThemePreference({
    required this._repository,
    void Function(ThemeMode mode)? applyTheme,
  }) : _apply = applyTheme ?? Get.changeThemeMode;

  final SettingsRepository _repository;
  final void Function(ThemeMode mode) _apply;

  /// What the store actually held, so a caller can tell "no preference" from a
  /// preference that was applied.
  ThemeChoice restored = ThemeChoice.system;

  @override
  void onInit() {
    super.onInit();
    restore();
  }

  Future<ThemeChoice> restore() async {
    final ThemeChoice choice =
        (await _repository.themeChoice()).valueOrNull ?? ThemeChoice.system;
    restored = choice;
    _apply(choice.mode);
    return choice;
  }
}
