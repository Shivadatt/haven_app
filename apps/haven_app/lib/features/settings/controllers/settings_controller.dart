import 'package:flutter/material.dart' show ThemeMode;
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../data/settings_repository.dart';

/// The two things a parent may actually change here: how Haven looks, and
/// whether this phone may show alerts.
///
/// The theme is applied the moment it is chosen and *then* written to storage,
/// so a phone that cannot keep the preference still gives the parent the change
/// they asked for — and says out loud that it may not survive a restart.
final class SettingsController extends GetxController {
  SettingsController({
    required this._repository,
    void Function(ThemeMode mode)? applyTheme,
  }) : _apply = applyTheme ?? Get.changeThemeMode;

  final SettingsRepository _repository;
  final void Function(ThemeMode mode) _apply;

  final Rx<ThemeChoice> theme = ThemeChoice.system.obs;
  final Rx<NotificationAccess> notifications =
      NotificationAccess.unavailable.obs;
  final RxBool isLoading = true.obs;
  final RxnString message = RxnString();

  /// Why a permission prompt is impossible, when it is — read from the
  /// repository so the page never has to invent the reason.
  final Rxn<BlockedFailure> notificationPrompt = Rxn<BlockedFailure>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final Result<ThemeChoice> stored = await _repository.themeChoice();
    final Result<NotificationAccess> access = await _repository
        .notificationAccess();
    if (isClosed) return;
    theme.value = stored.valueOrNull ?? ThemeChoice.system;
    notifications.value = access.valueOrNull ?? NotificationAccess.unavailable;
    message.value =
        stored.failureOrNull?.message ?? access.failureOrNull?.message;
    isLoading.value = false;
  }

  Future<void> chooseTheme(ThemeChoice choice) async {
    if (choice == theme.value) return;
    theme.value = choice;
    _apply(choice.mode);
    final HavenFailure? failure = (await _repository.saveThemeChoice(
      choice,
    )).failureOrNull;
    if (isClosed || failure == null) return;
    message.value = failure.message;
  }

  bool get canAskForNotifications =>
      notifications.value == NotificationAccess.denied;

  /// The OS prompt belongs to the OS. Haven asks once per press and reports the
  /// answer it got — never a guessed "granted".
  Future<void> askForNotifications() async {
    if (!canAskForNotifications) return;
    final Result<bool> answer = await _repository.requestNotificationAccess();
    if (isClosed) return;
    final HavenFailure? failure = answer.failureOrNull;
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
    message.value =
        'Your phone did not allow notifications. You can change that in its '
        'settings for Haven.';
  }
}
