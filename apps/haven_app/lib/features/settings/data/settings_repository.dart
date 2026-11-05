import 'package:flutter/material.dart' show ThemeMode;
import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import '../../../core/constants/haven_config.dart';
import '../../../core/storage/preferences_store.dart';
import 'settings_models.dart';

/// The parent's appearance choice.
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

extension ThemeChoiceMode on ThemeChoice {
  ThemeMode get mode => switch (this) {
    ThemeChoice.system => ThemeMode.system,
    ThemeChoice.light => ThemeMode.light,
    ThemeChoice.dark => ThemeMode.dark,
  };
}

enum NotificationAccess { granted, denied, unavailable }

abstract interface class SettingsRepository {
  Future<Result<ThemeChoice>> themeChoice();
  Future<Result<void>> saveThemeChoice(ThemeChoice choice);
  Future<Result<NotificationAccess>> notificationAccess();
  Future<Result<bool>> requestNotificationAccess();
  Future<Result<NotificationPreferences>> notificationPreferences();
  Future<Result<void>> saveNotificationPreferences(NotificationPreferences prefs);
  Future<Result<ParentProfileSummary?>> parentProfile();
  Future<Result<void>> updateParentName(String name);
  Future<Result<void>> signOut();
  Future<Result<void>> resetDemoData();
  Future<Result<void>> resetAllData();
}

final class HavenSettingsRepository implements SettingsRepository {
  HavenSettingsRepository({
    required PreferencesStore Function() prefs,
    required PushTransport Function() push,
    required bool Function() messagingConfigured,
  }) : _prefs = prefs,
       _push = push,
       _messagingConfigured = messagingConfigured;

  final PreferencesStore Function() _prefs;
  final PushTransport Function() _push;
  final bool Function() _messagingConfigured;

  factory HavenSettingsRepository.live() => HavenSettingsRepository(
    prefs: () => Get.find<PreferencesStore>(),
    push: () => HavenBackend.push,
    messagingConfigured: () =>
        Get.isRegistered<HavenConfig>() &&
        Get.find<HavenConfig>().endpoints.hasFirebase,
  );

  @override
  Future<Result<ThemeChoice>> themeChoice() async {
    final String? stored = await _prefs().read(PreferenceKey.themeMode);
    return Ok<ThemeChoice>(ThemeChoice.fromWire(stored));
  }

  @override
  Future<Result<void>> saveThemeChoice(ThemeChoice choice) async {
    final bool kept = await _prefs().write(PreferenceKey.themeMode, choice.wire);
    return kept
        ? okVoid()
        : const Err<void>(
            StorageFailure(
              'This phone could not keep the setting, so it may change back '
              'after a restart.',
              detail: 'secure storage refused the write',
            ),
          );
  }

  @override
  Future<Result<NotificationAccess>> notificationAccess() async {
    if (!_messagingConfigured()) return Ok(NotificationAccess.unavailable);
    return Ok(await _push().granted ? NotificationAccess.granted : NotificationAccess.denied);
  }

  @override
  Future<Result<bool>> requestNotificationAccess() async {
    if (!_messagingConfigured()) {
      return blocked(
        'this build has no Firebase project configured, so there is no push '
        'registration to ask permission for',
        requirement: 'Haven cannot ask for notification permission in this build yet.',
      );
    }
    return Ok<bool>(await _push().requestPermission());
  }

  @override
  Future<Result<NotificationPreferences>> notificationPreferences() async {
    final p = _prefs();
    final st = (await p.read(PreferenceKey.notifScreenTime)) != 'false';
    final bt = (await p.read(PreferenceKey.notifBedtime)) != 'false';
    final sz = (await p.read(PreferenceKey.notifSafeZones)) != 'false';
    final ai = (await p.read(PreferenceKey.notifAppInstalls)) != 'false';
    return Ok(NotificationPreferences(
      screenTimeAlerts: st,
      bedtimeAlerts: bt,
      safeZoneAlerts: sz,
      appInstallAlerts: ai,
    ));
  }

  @override
  Future<Result<void>> saveNotificationPreferences(NotificationPreferences prefs) async {
    final p = _prefs();
    await p.write(PreferenceKey.notifScreenTime, prefs.screenTimeAlerts.toString());
    await p.write(PreferenceKey.notifBedtime, prefs.bedtimeAlerts.toString());
    await p.write(PreferenceKey.notifSafeZones, prefs.safeZoneAlerts.toString());
    await p.write(PreferenceKey.notifAppInstalls, prefs.appInstallAlerts.toString());
    return okVoid();
  }

  @override
  Future<Result<ParentProfileSummary?>> parentProfile() async {
    final sRes = await HavenBackend.auth.currentSession();
    final session = sRes.valueOrNull;
    if (session == null) return const Ok(null);
    final profRes = await HavenBackend.profiles.load(session.userId);
    final row = profRes.valueOrNull;
    if (row != null) return Ok(ParentProfileSummary.fromRow(row));
    return Ok(ParentProfileSummary(
      id: session.userId,
      email: session.email ?? '',
      displayName: '',
      role: session.role ?? 'parent',
    ));
  }

  @override
  Future<Result<void>> updateParentName(String name) async {
    final sRes = await HavenBackend.auth.currentSession();
    final session = sRes.valueOrNull;
    if (session == null) return const Err(AuthFailure('No active session.'));
    await _prefs().write(PreferenceKey.parentDisplayName, name.trim());
    return HavenBackend.profiles.updateDisplayName(session.userId, name.trim());
  }

  @override
  Future<Result<void>> signOut() async => HavenBackend.auth.signOut();

  @override
  Future<Result<void>> resetDemoData() async {
    if (Get.isRegistered<LocalTables>()) {
      return Get.find<LocalTables>().clearDemoData();
    }
    return okVoid();
  }

  @override
  Future<Result<void>> resetAllData() async {
    if (Get.isRegistered<LocalTables>()) {
      final res = await Get.find<LocalTables>().resetAll();
      if (res.isErr) return res;
    }
    await signOut();
    return okVoid();
  }
}
