import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../app/routes/app_routes.dart';
import '../data/policies_models.dart';
import '../data/policies_repository.dart';

/// The policy versions on record for this family.
///
/// This is a read of what was written and what a device said back. The two
/// refusals — no way to write a version, and no specification for the rules
/// inside one — are shown on the screen, not hidden behind a control.
final class PoliciesController extends GetxController {
  PoliciesController({
    required this._repository,
    this.deviceId = '',
    void Function(String route, Object? arg)? replace,
  }) : _replace =
           replace ??
           ((String route, Object? arg) =>
               Get.offAllNamed(route, arguments: arg));

  final PoliciesRepository _repository;
  final void Function(String route, Object? arg) _replace;

  /// The route argument this screen was opened with. Empty means the family.
  final String deviceId;

  final RxBool isLoading = true.obs;
  final Rx<Result<PolicyBoard?>?> board = Rx<Result<PolicyBoard?>?>(null);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<PolicyBoard?> read = await _repository.load(
      deviceId: deviceId.isEmpty ? null : deviceId,
    );
    if (isClosed) return;
    board.value = read;
    isLoading.value = false;
  }

  @override
  Future<void> refresh() async {
    board.value = await _repository.load(
      deviceId: deviceId.isEmpty ? null : deviceId,
    );
  }

  void goToSetup() => _replace(AppRoutes.onboarding, null);
}
