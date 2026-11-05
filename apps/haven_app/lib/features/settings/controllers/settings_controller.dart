import 'package:flutter/material.dart' show ThemeMode;
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/permissions/channel_device_state.dart';
import '../../../core/permissions/native_device_state.dart';
import '../data/settings_models.dart';
import '../data/settings_repository.dart';

/// Manages appearance, notification preferences, parent profile, and local data resets.
final class SettingsController extends GetxController {
  SettingsController({
    required SettingsRepository repository,
    void Function(ThemeMode mode)? applyTheme,
    NativeDeviceState? deviceState,
    void Function(String route)? navigate,
  }) : _repository = repository,
        _apply = applyTheme ?? Get.changeThemeMode,
       _device = deviceState ?? const ChannelNativeDeviceState(),
       _navigate = navigate ?? ((route) => Get.offAllNamed(route));

  final SettingsRepository _repository;
  final void Function(ThemeMode mode) _apply;
  final NativeDeviceState _device;
  final void Function(String route) _navigate;

  final Rx<ThemeChoice> theme = ThemeChoice.system.obs;
  final Rx<NotificationAccess> notifications = NotificationAccess.unavailable.obs;
  final Rx<NotificationPreferences> notificationPrefs =
      NotificationPreferences.defaults.obs;
  final Rxn<ParentProfileSummary> parentProfile = Rxn<ParentProfileSummary>();

  final RxBool isLoading = true.obs;
  final RxBool isResetting = false.obs;
  final RxnString message = RxnString();
  final Rxn<DeviceStateReport> deviceState = Rxn<DeviceStateReport>();
  final Rxn<HavenFailure> deviceStateFailure = Rxn<HavenFailure>();
  final Rxn<BlockedFailure> notificationPrompt = Rxn<BlockedFailure>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final stored = await _repository.themeChoice();
    final access = await _repository.notificationAccess();
    final prefs = await _repository.notificationPreferences();
    final profile = await _repository.parentProfile();
    final osAnswers = await _device.read();

    if (isClosed) return;
    theme.value = stored.valueOrNull ?? ThemeChoice.system;
    notifications.value = access.valueOrNull ?? NotificationAccess.unavailable;
    if (prefs.isOk) notificationPrefs.value = prefs.valueOrNull!;
    parentProfile.value = profile.valueOrNull;
    deviceState.value = osAnswers.valueOrNull;
    deviceStateFailure.value = osAnswers.failureOrNull;
    message.value = stored.failureOrNull?.message ?? access.failureOrNull?.message;
    isLoading.value = false;
  }

  Future<void> chooseTheme(ThemeChoice choice) async {
    if (choice == theme.value) return;
    theme.value = choice;
    _apply(choice.mode);
    final failure = (await _repository.saveThemeChoice(choice)).failureOrNull;
    if (isClosed || failure == null) return;
    message.value = failure.message;
  }

  bool get canAskForNotifications => notifications.value == NotificationAccess.denied;

  Future<void> askForNotifications() async {
    if (!canAskForNotifications) return;
    final answer = await _repository.requestNotificationAccess();
    if (isClosed) return;
    final failure = answer.failureOrNull;
    notificationPrompt.value = failure is BlockedFailure ? failure : null;
    if (failure != null) {
      message.value = failure.message;
      return;
    }
    if (answer.valueOrNull ?? false) {
      notifications.value = NotificationAccess.granted;
      message.value = null;
      return;
    }
    message.value = 'Your phone did not allow notifications. You can change that in its settings.';
  }

  Future<void> updateNotificationPref({
    bool? screenTime,
    bool? bedtime,
    bool? safeZones,
    bool? appInstalls,
  }) async {
    final updated = notificationPrefs.value.copyWith(
      screenTimeAlerts: screenTime,
      bedtimeAlerts: bedtime,
      safeZoneAlerts: safeZones,
      appInstallAlerts: appInstalls,
    );
    notificationPrefs.value = updated;
    await _repository.saveNotificationPreferences(updated);
  }

  Future<bool> updateParentName(String name) async {
    final res = await _repository.updateParentName(name);
    if (res.isOk) {
      final cur = parentProfile.value;
      if (cur != null) {
        parentProfile.value = ParentProfileSummary(
          id: cur.id,
          email: cur.email,
          displayName: name.trim(),
          role: cur.role,
        );
      }
      return true;
    }
    message.value = res.failureOrNull?.message;
    return false;
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _navigate(AppRoutes.signIn);
  }

  Future<void> resetDemoData() async {
    isResetting.value = true;
    final res = await _repository.resetDemoData();
    isResetting.value = false;
    if (res.isOk) {
      message.value = 'Demo data reset complete. Personal user data was preserved.';
    } else {
      message.value = res.failureOrNull?.message ?? 'Demo data reset failed.';
    }
  }

  Future<void> resetAllData() async {
    isResetting.value = true;
    final res = await _repository.resetAllData();
    isResetting.value = false;
    if (res.isOk) {
      _navigate(AppRoutes.onboarding);
    } else {
      message.value = res.failureOrNull?.message ?? 'Full reset failed.';
    }
  }
}
