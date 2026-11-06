import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart' show isCorruptLocalDatabase;
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../app/routes/child_routes.dart';
import '../../../core/session/child_local_session.dart';
import '../../../core/storage/child_database.dart';
import '../../../core/storage/child_profile_repository.dart';

/// The real boot (brief §4 F): open storage, load the session and profile,
/// then decide the route — profile home when setup is genuinely finished,
/// onboarding otherwise (which itself resumes the persisted step + draft).
///
/// Dependencies are providers, not instances, because the storage lane only
/// exists after [openStorage] succeeds; a screen resolving it earlier gets a
/// clear `Get.find` failure, never a half-built repository.
final class SplashController extends GetxController {
  SplashController({
    required this.openStorage,
    required this.resetStorage,
    required this.profileRepository,
    required this.sessionStore,
    required this.navigate,
  });

  final Future<Result<ChildDatabase>> Function() openStorage;

  /// The developer exit for a CORRUPT document — explicit, never automatic.
  /// [ChildDataResetter.clearAll]'s named parameters are bound at the
  /// binding file, keeping this signature plain.
  final Future<Result<void>> Function() resetStorage;

  final ChildProfileRepository Function() profileRepository;
  final ChildSessionStore Function() sessionStore;
  final void Function(String route) navigate;

  final RxBool isBooting = true.obs;
  final RxnString errorMessage = RxnString();
  final RxBool storageIsCorrupt = false.obs;
  final RxBool isResetting = false.obs;

  @override
  void onInit() {
    super.onInit();
    boot();
  }

  Future<void> boot() async {
    isBooting.value = true;
    errorMessage.value = null;
    storageIsCorrupt.value = false;

    final opened = await openStorage();
    if (isClosed) return;
    if (opened case Err<ChildDatabase>()) {
      _fail(opened.failureOrNull!);
      return;
    }

    final profiles = await profileRepository().read();
    if (isClosed) return;
    if (profiles case Err<Profile?>()) {
      _fail(profiles.failureOrNull!);
      return;
    }
    final sessionRes = await sessionStore().read();
    if (isClosed) return;
    if (sessionRes case Err<ChildLocalSession?>()) {
      _fail(sessionRes.failureOrNull!);
      return;
    }

    final profile = profiles.valueOrNull;
    final session = sessionRes.valueOrNull;
    // Setup counts as finished only when the remembered session points at
    // the profile that is actually on the device — never on either alone.
    final done =
        session != null && profile != null && session.profileId == profile.id;
    isBooting.value = false;
    navigate(done ? ChildRoutes.profile : ChildRoutes.onboarding);
  }

  void _fail(HavenFailure failure) {
    isBooting.value = false;
    errorMessage.value = failure.message;
    storageIsCorrupt.value = isCorruptLocalDatabase(failure);
  }

  /// Corrupt-document repair: replace the damaged bytes, then boot again.
  /// [verifyReadableFirst] is false here on purpose — the unreadable document
  /// is exactly what this action was confirmed to replace.
  Future<void> resetAndReboot() async {
    if (isResetting.value) return;
    isResetting.value = true;
    final done = await resetStorage();
    if (isClosed) return;
    isResetting.value = false;
    if (done.isErr) {
      errorMessage.value = done.failureOrNull!.message;
      return;
    }
    await boot();
  }
}
