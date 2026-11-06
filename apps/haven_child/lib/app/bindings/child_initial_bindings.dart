import 'dart:async';

import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../core/constants/child_config.dart';
import '../../core/device/device_information.dart';
import '../../core/device/real_device_information.dart';
import '../../core/permissions/permission_status_source.dart';
import '../../core/permissions/unconfigured_permission_status_source.dart';
import '../../core/session/child_local_session.dart';
import '../../core/storage/child_database.dart';
import '../../core/storage/child_profile_repository.dart';
import '../../core/storage/local_child_profile_repository.dart';
import '../../core/storage/onboarding_state_store.dart';

/// Startup bindings: the build configuration, the honest no-op platform
/// readers, and the one local-storage lane — mirroring the parent's
/// `InitialBindings` register/start split.
///
/// `register` is synchronous and idempotent (hot restart re-runs `build`).
/// [startStorage] is the async half: the splash screen awaits it and shows
/// real progress, while the permanent seams registered here let every other
/// screen resolve honest `Unconfigured`-style readers even before storage is
/// up — they never fabricate success.
final class ChildInitialBindings extends Bindings {
  static bool _registered = false;
  static Future<Result<ChildDatabase>>? _storage;

  static void register(ChildConfig config) {
    if (_registered && Get.isRegistered<ChildConfig>()) return;
    _registered = true;
    Get.put<ChildConfig>(config, permanent: true);
    Get.put<DeviceInformation>(const RealDeviceInformation(), permanent: true);
    Get.put<PermissionStatusSource>(
      const UnconfiguredPermissionStatusSource(),
      permanent: true,
    );
  }

  @override
  void dependencies() => unawaited(startStorage());

  /// Opens the local document once and returns the same future to every
  /// caller. A failed open is NOT cached: the splash's retry (and Agent 3's
  /// tests) get a genuine second attempt.
  static Future<Result<ChildDatabase>> startStorage({String? directory}) {
    final existing = _storage;
    if (existing != null) return existing;
    final attempt = _openAndRegister(directory);
    _storage = attempt;
    unawaited(
      attempt.then<void>((result) {
        if (result.isErr && identical(_storage, attempt)) _storage = null;
      }),
    );
    return attempt;
  }

  static Future<Result<ChildDatabase>> _openAndRegister(String? directory) async {
    final opened = directory == null
        ? await ChildDatabase.open()
        : await ChildDatabase.openAt(directory);
    if (opened case Ok<ChildDatabase>(:final value)) {
      Get.put<ChildDatabase>(value, permanent: true);
      Get.put<ChildProfileRepository>(
        LocalChildProfileRepository(value.tables),
        permanent: true,
      );
      Get.put<OnboardingStateStore>(
        LocalOnboardingStateStore(value.localState),
        permanent: true,
      );
      Get.put<ChildSessionStore>(
        LocalChildSessionStore(value.localState),
        permanent: true,
      );
    }
    return opened;
  }

  /// Test seam: a fresh isolate must not inherit a previous registration
  /// (Agent 3 relies on this between suites). Also clears the storage-path
  /// override so a leaked test path cannot redirect a later suite.
  static void resetForTests() {
    _registered = false;
    _storage = null;
    Get.reset();
    unregisterStorageSeams();
  }

  /// GetxController disposal is asynchronous, so [Get.reset] alone can leave
  /// one stale write behind; tests that assert on the store afterwards call
  /// this after a `pump()` as well.
  static void unregisterStorageSeams() {
    if (Get.isRegistered<ChildDatabase>()) {
      Get.delete<ChildDatabase>(force: true);
    }
    if (Get.isRegistered<ChildProfileRepository>()) {
      Get.delete<ChildProfileRepository>(force: true);
    }
    if (Get.isRegistered<OnboardingStateStore>()) {
      Get.delete<OnboardingStateStore>(force: true);
    }
    if (Get.isRegistered<ChildSessionStore>()) {
      Get.delete<ChildSessionStore>(force: true);
    }
  }
}
