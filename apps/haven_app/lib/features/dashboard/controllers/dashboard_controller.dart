import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/dashboard_repository.dart';

/// The screen a parent lands on.
///
/// It reports what the backend actually returned and nothing else: no rounded
/// figure, no "3 hours today" that was never read, no green tick on a device the
/// app cannot list. Each section owns its own failure, so one unreadable read
/// cannot blank the whole page.
final class DashboardController extends GetxController {
  DashboardController({
    required this._repository,
    void Function(String route, Object? arg)? push,
    void Function(String route, Object? arg)? replace,
  }) : _push =
           push ??
           ((String route, Object? arg) => Get.toNamed(route, arguments: arg)),
       _replace =
           replace ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final DashboardRepository _repository;

  /// Two ways to move: a parent looking at a child stays able to come back, but
  /// a parent who has no family yet must not be able to land back on an empty
  /// dashboard.
  final void Function(String route, Object? arg) _push;
  final void Function(String route, Object? arg) _replace;

  final RxBool isLoading = true.obs;
  final Rx<Result<DashboardData>?> data = Rx<Result<DashboardData>?>(null);

  /// Why the device section is a refusal instead of a list.
  final Rxn<BlockedFailure> deviceGap = Rxn<BlockedFailure>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<DashboardData> result = await _repository.load();
    deviceGap.value = _blocked(await _repository.pairedDevices());
    if (isClosed) return;
    data.value = result;
    isLoading.value = false;
  }

  /// Pull-to-refresh: the same read, without the spinner that would hide the
  /// numbers already on the page.
  @override
  Future<void> refresh() async {
    final Result<DashboardData> result = await _repository.load();
    if (isClosed) return;
    data.value = result;
  }

  bool get needsSetup => data.value?.valueOrNull?.needsSetup ?? false;

  void goToSetup() => _replace(AppRoutes.onboarding, null);
  void goToFamily() => _push(AppRoutes.family, null);
  void goToChild(String childUserId) =>
      _push(AppRoutes.childProfile, childUserId);
  void goToSettings() => _push(AppRoutes.settings, null);

  static BlockedFailure? _blocked(Result<void> result) {
    final HavenFailure? failure = result.failureOrNull;
    return failure is BlockedFailure ? failure : null;
  }
}
