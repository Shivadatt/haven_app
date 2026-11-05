import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/activity_models.dart';
import '../data/activity_repository.dart';

/// The activity screen: the days this family may read, and the owner each row
/// still cannot be named for.
///
/// The gap is read out of the repository rather than typed here, so the parent
/// sees the sentence about the missing grant instead of a paraphrase of it.
final class ActivityController extends GetxController {
  ActivityController({
    required ActivityRepository repository,
    this.deviceId = '',
    void Function(String route, Object? arg)? replace,
  }) : _repository = repository,
        _replace =
           replace ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final ActivityRepository _repository;
  final void Function(String route, Object? arg) _replace;

  /// The route argument this screen was opened with. Empty means the whole
  /// family, which is the only thing reachable while the device lane is refused.
  final String deviceId;

  final RxBool isLoading = true.obs;
  final Rx<Result<UsageBoard?>?> board = Rx<Result<UsageBoard?>?>(null);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<UsageBoard?> read = await _repository.load(
      deviceId: deviceId.isEmpty ? null : deviceId,
    );
    if (isClosed) return;
    board.value = read;
    isLoading.value = false;
  }

  /// Pull-to-refresh keeps what is already on the page while the re-read happens.
  Future<void> reload() async {
    final Result<UsageBoard?> read = await _repository.load(
      deviceId: deviceId.isEmpty ? null : deviceId,
    );
    if (isClosed) return;
    board.value = read;
  }

  /// Usage belongs to a family. With none, the honest answer is setup, not a
  /// blank list.
  void goToSetup() => _replace(AppRoutes.onboarding, null);
}
