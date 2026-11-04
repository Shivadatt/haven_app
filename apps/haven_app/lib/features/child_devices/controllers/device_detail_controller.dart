import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../app/routes/app_routes.dart';
import '../data/devices_repository.dart';

/// One device, and the two things a parent would want to do with it.
///
/// All three are refusals in this build, and the page shows them instead of an
/// empty record: a blank detail screen would read as "this device has no
/// information", which is a different claim from "this app cannot read device
/// rows".
final class DeviceDetailController extends GetxController {
  DeviceDetailController({
    required this.deviceId,
    required this._repository,
    void Function(String route, Object? arg)? push,
  }) : _push =
           push ??
           ((String route, Object? arg) => Get.toNamed(route, arguments: arg));

  /// Empty when the route was opened without a [DeviceRouteArgs]. Nothing is
  /// read for a device that was never named.
  final String deviceId;

  final DevicesRepository _repository;
  final void Function(String route, Object? arg) _push;

  final RxBool isLoading = true.obs;
  final Rx<Result<Device>?> device = Rx<Result<Device>?>(null);

  final Rxn<BlockedFailure> revokeGap = Rxn<BlockedFailure>();
  final Rxn<BlockedFailure> recoveryGap = Rxn<BlockedFailure>();

  bool get hasDeviceId => deviceId.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (!hasDeviceId) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    device.value = await _repository.device(deviceId);
    revokeGap.value = _blocked(await _repository.revoke(deviceId));
    recoveryGap.value = _blocked(await _repository.requestRecovery(deviceId));
    if (isClosed) return;
    isLoading.value = false;
  }

  static BlockedFailure? _blocked(Result<void> result) {
    final HavenFailure? failure = result.failureOrNull;
    return failure is BlockedFailure ? failure : null;
  }

  /// The reads that work for this device even while its own row does not:
  /// `usage_daily`, `location_events`, `device_commands` and `device_policies`
  /// all carry a SELECT grant for a parent. Each screen takes this id as its
  /// route argument and still filters by the caller's own family, so a stale id
  /// cannot open another family's rows.
  void goToActivity() => _push(AppRoutes.activity, deviceId);
  void goToLocation() => _push(AppRoutes.location, deviceId);
  void goToCommands() => _push(AppRoutes.commands, deviceId);
  void goToPolicies() => _push(AppRoutes.policies, deviceId);
}
