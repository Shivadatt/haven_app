import 'dart:async';

import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/haven_config.dart';
import '../../core/storage/preferences_store.dart';
import '../../core/storage/secure_vault.dart';
import '../../features/authentication/data/auth_repository.dart';
import '../../features/authentication/services/session_watch.dart';
import '../../features/settings/bindings/settings_bindings.dart';

/// Startup bindings: build configuration, the secret vault, and one call into
/// `haven_api` that registers every data seam.
///
/// `register` is synchronous and idempotent because `HavenApp.build` may run
/// more than once (hot restart, theme change). The network half is separated on
/// purpose: the splash screen awaits [startBackend] and shows real progress,
/// while every other screen can already resolve the seams — they read back as
/// `Unconfigured*` until the install completes, never as a fabricated success.
final class InitialBindings extends Bindings {
  @override
  void dependencies() => unawaited(startBackend());

  static bool _registered = false;
  static Future<HavenBackendHandle>? _install;
  static Future<HavenBackendHandle>? _offline;

  static void register(HavenConfig config) {
    if (_registered && Get.isRegistered<HavenConfig>()) return;
    _registered = true;
    Get.put<HavenConfig>(config, permanent: true);
    Get.put<SecretVault>(SecureVault(), permanent: true);
    Get.put<PreferencesStore>(
      VaultPreferences(() => Get.find<SecretVault>()),
      permanent: true,
    );
  }

  /// Installs the backend once and returns the same future to every caller.
  ///
  /// Offline mode (`--dart-define=HAVEN_OFFLINE_MODE=true`) goes to
  /// `OfflineHavenBackend` and never touches Supabase or Firebase.
  /// [offlineDirectory] lets a test point the local engine at a temp directory.
  static Future<HavenBackendHandle> startBackend({String? offlineDirectory}) {
    final config = Get.find<HavenConfig>();
    if (config.offlineMode) {
      return _offline ??= _installOffline(offlineDirectory);
    }
    return _install ??= HavenBackend.install(
      endpoints: config.endpoints,
      secretVault: Get.find<SecretVault>(),
    ).then(_afterInstall);
  }

  static Future<HavenBackendHandle> _installOffline(String? directory) async {
    final path =
        directory ??
        (await getApplicationDocumentsDirectory()).path;
    final handle = await OfflineHavenBackend.installLocal(
      store: FileLocalStore(path),
      secretVault: Get.find<SecretVault>(),
    );
    return _afterInstall(handle);
  }
  static HavenBackendHandle _afterInstall(
    HavenBackendHandle handle,
  ) {
    // One listener for the whole app: a session that ends by itself has to be
    // said out loud, not discovered on the next failed request.
    Get.put<SessionWatch>(
      SessionWatch(repository: HavenAuthRepository.live()),
      permanent: true,
    );
    // The stored appearance choice is applied here, once, so the first
    // screen the parent sees is already the one they picked.
    SettingsDependencies.startThemePreference();
    return handle;
  }

  /// Test seam: a fresh isolate must not inherit a previous registration.
  static void resetForTests() {
    _registered = false;
    _install = null;
    _offline = null;
    Get.reset();
  }
}
