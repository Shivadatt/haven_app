import 'package:flutter/material.dart' show ThemeMode;
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import '../../../core/constants/haven_config.dart';
import '../../../core/storage/preferences_store.dart';

/// The parent's appearance choice. `system` is the default because the app has
/// no opinion about a phone's own schedule.
enum ThemeChoice {
  system('system', 'Match the phone'),
  light('light', 'Light'),
  dark('dark', 'Dark');

  const ThemeChoice(this.wire, this.label);

  final String wire;
  final String label;

  static ThemeChoice fromWire(String? value) => values.firstWhere(
    (c) => c.wire == value,
    orElse: () => ThemeChoice.system,
  );
}

/// The mapping the app applies. It lives here so a stored choice can never be
/// read in one place and honoured in another.
extension ThemeChoiceMode on ThemeChoice {
  ThemeMode get mode => switch (this) {
    ThemeChoice.system => ThemeMode.system,
    ThemeChoice.light => ThemeMode.light,
    ThemeChoice.dark => ThemeMode.dark,
  };
}

/// What this phone reports for notification permission.
///
/// `unavailable` is deliberately not `denied`: a build with no Firebase project
/// configured cannot ask, and saying "denied" would blame the parent for a gap
/// in the build.
enum NotificationAccess { granted, denied, unavailable }

/// The two local settings this app owns, plus the one OS permission it needs.
abstract interface class SettingsRepository {
  Future<Result<ThemeChoice>> themeChoice();
  Future<Result<void>> saveThemeChoice(ThemeChoice choice);
  Future<Result<NotificationAccess>> notificationAccess();

  /// True only when the OS says yes. The prompt itself is the OS's, not Haven's.
  Future<Result<bool>> requestNotificationAccess();
}

final class HavenSettingsRepository implements SettingsRepository {
  HavenSettingsRepository({
    required this._prefs,
    required this._push,
    required this._messagingConfigured,
  });

  final PreferencesStore Function() _prefs;
  final PushTransport Function() _push;
  final bool Function() _messagingConfigured;

  factory HavenSettingsRepository.live() => HavenSettingsRepository(
    prefs: () => Get.find<PreferencesStore>(),
    push: () => HavenBackend.push,
    // Guarded, because a build with no configuration has nothing to ask.
    messagingConfigured: () =>
        Get.isRegistered<HavenConfig>() &&
        Get.find<HavenConfig>().endpoints.hasFirebase,
  );

  @override
  Future<Result<ThemeChoice>> themeChoice() async {
    final String? stored = await _prefs().read(PreferenceKey.themeMode);
    // A vault that cannot read reports null rather than failing, so the worst
    // case here is the default choice — never a broken screen.
    return Ok<ThemeChoice>(ThemeChoice.fromWire(stored));
  }

  @override
  Future<Result<void>> saveThemeChoice(ThemeChoice choice) async {
    final bool kept = await _prefs().write(
      PreferenceKey.themeMode,
      choice.wire,
    );
    return kept
        ? okVoid()
        : Err<void>(
            const StorageFailure(
              'This phone could not keep the setting, so it may change back '
              'after a restart.',
              detail: 'secure storage refused the write',
            ),
          );
  }

  @override
  Future<Result<NotificationAccess>> notificationAccess() async {
    if (!_messagingConfigured()) {
      return Ok<NotificationAccess>(NotificationAccess.unavailable);
    }
    return Ok<NotificationAccess>(
      await _push().granted
          ? NotificationAccess.granted
          : NotificationAccess.denied,
    );
  }

  @override
  Future<Result<bool>> requestNotificationAccess() async {
    if (!_messagingConfigured()) {
      return blocked(
        'this build has no Firebase project configured, so there is no push '
        'registration to ask permission for',
        requirement:
            'Haven cannot ask for notification permission in this '
            'build yet.',
      );
    }
    return Ok<bool>(await _push().requestPermission());
  }
}
