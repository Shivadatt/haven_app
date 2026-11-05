import 'package:haven_api/haven_api.dart';

/// A tiny key-value preference store, kept separate from [SecretVault] even
/// though it is implemented over it.
///
/// This build has one persistent local store — the platform keystore behind
/// `flutter_secure_storage` — and no dependency for an unencrypted one. A theme
/// choice is not a secret, so it is written through the vault but typed as a
/// preference: nothing that reads [PreferencesStore] can be mistaken for code
/// that handles credentials, and nothing that handles credentials is asked to
/// hold a preference by accident.
abstract interface class PreferencesStore {
  Future<String?> read(String key);
  Future<bool> write(String key, String value);
}

final class VaultPreferences implements PreferencesStore {
  VaultPreferences(this._vault);

  /// A provider, because the vault is registered at startup and a settings
  /// controller can outlive a hot restart.
  final SecretVault Function() _vault;

  @override
  Future<String?> read(String key) => _vault().read(key);

  @override
  Future<bool> write(String key, String value) => _vault().write(key, value);
}

/// In-memory fallback for preferences when vault is not yet registered.
final class InMemoryPreferencesStore implements PreferencesStore {
  final Map<String, String> _data = <String, String>{};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<bool> write(String key, String value) async {
    _data[key] = value;
    return true;
  }
}

/// The keys this app stores. Adding one here is the only way to add a preference.
abstract final class PreferenceKey {
  static const themeMode = 'pref.theme_mode';
  static const notifScreenTime = 'pref.notif_screen_time';
  static const notifBedtime = 'pref.notif_bedtime';
  static const notifSafeZones = 'pref.notif_safe_zones';
  static const notifAppInstalls = 'pref.notif_app_installs';
  static const policyConfig = 'pref.policy_config';
  static const parentDisplayName = 'pref.parent_display_name';
  static const onboardingStep = 'onboarding.step';
  static const onboardingCompleted = 'onboarding.completed';
  static const onboardingEthicsAcknowledged = 'onboarding.ethics_acknowledged';
}
