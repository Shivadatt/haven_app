import 'package:get/get.dart';

import '../controllers/settings_controller.dart';
import '../data/settings_repository.dart';
import '../services/theme_preference.dart';

/// DI for the settings screens.
///
/// The repository is permanent because the theme service and two screens share
/// it; the controller is not, so opening settings always re-reads what the phone
/// currently allows rather than showing a stale chip.
abstract final class SettingsDependencies {
  static SettingsRepository ensureRepository() {
    if (!Get.isRegistered<SettingsRepository>()) {
      Get.put<SettingsRepository>(
        HavenSettingsRepository.live(),
        permanent: true,
      );
    }
    return Get.find<SettingsRepository>();
  }

  static SettingsController ensureController() {
    if (!Get.isRegistered<SettingsController>()) {
      Get.put<SettingsController>(
        SettingsController(repository: ensureRepository()),
      );
    }
    return Get.find<SettingsController>();
  }

  /// Started once at launch, before any screen, so a saved appearance choice is
  /// in effect on the first frame the parent sees.
  static void startThemePreference() {
    if (!Get.isRegistered<ThemePreference>()) {
      Get.put<ThemePreference>(
        ThemePreference(repository: ensureRepository()),
        permanent: true,
      );
    }
  }
}

final class SettingsBindings extends Bindings {
  @override
  void dependencies() => SettingsDependencies.ensureController();
}

final class PermissionStatusBindings extends Bindings {
  @override
  void dependencies() => SettingsDependencies.ensureController();
}

/// About reads only build configuration, so it needs no controller.
final class AboutBindings extends Bindings {
  @override
  void dependencies() {}
}
