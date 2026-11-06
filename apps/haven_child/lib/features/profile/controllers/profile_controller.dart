import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../app/routes/child_routes.dart';
import '../../../core/session/child_local_session.dart';
import '../../../core/storage/child_profile_repository.dart';

/// Loads the child's own profile for the home screen: the repository result
/// is kept verbatim so `ChildStateView` can render data / error / blocked /
/// empty honestly. "No profile row yet" is an empty state with a route to
/// setup — the contract's "profile does not exist yet" posture, not an error.
final class ProfileController extends GetxController {
  ProfileController({required this.profiles, required this.sessions});

  final ChildProfileRepository profiles;
  final ChildSessionStore sessions;

  final RxBool isLoading = true.obs;

  /// BUG FIX (Agent 3, Stage 1 test pass): `const Ok<Profile?>(null).obs`
  /// inferred `Rx<Ok<Profile?>>`, so the first refused read (an `Err`) threw
  /// a type error at runtime instead of rendering the refusal. Pinning the
  /// generic keeps the declared `Rx<Result<Profile?>>` honest.
  final Rx<Result<Profile?>> result =
      Rx<Result<Profile?>>(const Ok<Profile?>(null));

  /// Setup counts as complete only when the session names this profile —
  /// the same pairing rule the splash applies.
  final RxBool sessionMatches = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final loaded = await profiles.read();
    if (isClosed) return;
    if (loaded.isErr) {
      result.value = loaded;
      sessionMatches.value = false;
      isLoading.value = false;
      return;
    }
    final session = await sessions.read();
    if (isClosed) return;
    result.value = loaded;
    sessionMatches.value =
        session.valueOrNull != null &&
        loaded.valueOrNull != null &&
        session.valueOrNull!.profileId == loaded.valueOrNull!.id;
    isLoading.value = false;
  }

  Future<void> startSetup() async {
    await Get.toNamed(ChildRoutes.onboarding);
    if (isClosed) return;
    await load();
  }

  void openDevice() => Get.toNamed(ChildRoutes.device);

  void openPermissions() => Get.toNamed(ChildRoutes.permissions);
}
