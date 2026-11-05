import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:haven_app/core/storage/preferences_store.dart';
import 'package:haven_app/features/settings/controllers/settings_controller.dart';
import 'package:haven_app/features/settings/data/settings_repository.dart';

import '../permissions/fakes.dart';
import '../support/backend_fakes.dart';
import '../support/fakes.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  group('Settings Theme Persistence & Immediate Reactive Update', () {
    test('theme change applies immediately and persists to storage', () async {
      final applied = <ThemeMode>[];
      final fakeVault = FakeVault();
      final prefs = VaultPreferences(() => fakeVault);

      final repo = HavenSettingsRepository(
        prefs: () => prefs,
        push: () => FakePushTransport(),
        messagingConfigured: () => false,
      );

      final controller = SettingsController(
        repository: repo,
        applyTheme: applied.add,
        deviceState: FakeNativeDeviceState(unavailable()),
      );

      await controller.load();
      expect(controller.theme.value, ThemeChoice.system);

      await controller.chooseTheme(ThemeChoice.dark);
      expect(applied, [ThemeMode.dark]);
      expect(controller.theme.value, ThemeChoice.dark);

      // Verify persistent storage
      final stored = await prefs.read(PreferenceKey.themeMode);
      expect(stored, 'dark');

      // Next change to light
      await controller.chooseTheme(ThemeChoice.light);
      expect(applied, [ThemeMode.dark, ThemeMode.light]);
      expect(await prefs.read(PreferenceKey.themeMode), 'light');
    });

    test('notification preferences update local toggles and persist', () async {
      final fakeVault = FakeVault();
      final prefs = VaultPreferences(() => fakeVault);

      final repo = HavenSettingsRepository(
        prefs: () => prefs,
        push: () => FakePushTransport(),
        messagingConfigured: () => false,
      );

      final controller = SettingsController(
        repository: repo,
        deviceState: FakeNativeDeviceState(unavailable()),
      );

      await controller.load();
      expect(controller.notificationPrefs.value.screenTimeAlerts, isTrue);

      await controller.updateNotificationPref(screenTime: false, bedtime: false);
      expect(controller.notificationPrefs.value.screenTimeAlerts, isFalse);
      expect(controller.notificationPrefs.value.bedtimeAlerts, isFalse);
      expect(controller.notificationPrefs.value.safeZoneAlerts, isTrue);

      // Verify PreferencesStore
      expect(await prefs.read(PreferenceKey.notifScreenTime), 'false');
      expect(await prefs.read(PreferenceKey.notifBedtime), 'false');
    });
  });
}
