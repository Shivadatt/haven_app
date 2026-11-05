import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../app/routes/app_routes.dart';
import '../data/devices_repository.dart';

/// One device, and its actions.
final class DeviceDetailController extends GetxController {
  DeviceDetailController({
    required this.deviceId,
    required DevicesRepository repository,
    void Function(String route, Object? arg)? push,
    void Function()? back,
  }) : _repository = repository,
        _push =
           push ??
           ((String route, Object? arg) => Get.toNamed(route, arguments: arg)),
       _back = back ?? Get.back;

  final String deviceId;
  final DevicesRepository _repository;
  final void Function(String route, Object? arg) _push;
  final void Function() _back;

  final RxBool isLoading = true.obs;
  final RxBool isUnlinking = false.obs;
  final Rx<Result<Device>?> device = Rx<Result<Device>?>(null);

  final Rxn<BlockedFailure> revokeGap = Rxn<BlockedFailure>();
  final Rxn<BlockedFailure> recoveryGap = Rxn<BlockedFailure>();

  bool get hasDeviceId => deviceId.isNotEmpty;
  bool get canUnlink => revokeGap.value == null;

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
    revokeGap.value = _blocked(
      await _repository.revoke(deviceId, execute: false),
    );
    recoveryGap.value = _blocked(await _repository.requestRecovery(deviceId));
    if (isClosed) return;
    isLoading.value = false;
  }

  Future<bool> rename(String newName) async {
    final Result<void> result = await _repository.rename(
      deviceId: deviceId,
      name: newName,
    );
    if (result.isOk) {
      await load();
      return true;
    }
    return false;
  }

  Future<bool> assignChild(String childUserId) async {
    final Result<void> result = await _repository.assignChild(
      deviceId: deviceId,
      childUserId: childUserId,
    );
    if (result.isOk) {
      await load();
      return true;
    }
    return false;
  }

  Future<bool> unlinkDevice() async {
    isUnlinking.value = true;
    final Result<void> result = await _repository.unlink(deviceId);
    if (isClosed) return false;
    isUnlinking.value = false;
    if (result.isOk) {
      _back();
      return true;
    }
    return false;
  }

  static BlockedFailure? _blocked(Result<void> result) {
    final HavenFailure? failure = result.failureOrNull;
    return failure is BlockedFailure ? failure : null;
  }

  void goToActivity() => _push(AppRoutes.activity, deviceId);
  void goToLocation() => _push(AppRoutes.location, deviceId);
  void goToCommands() => _push(AppRoutes.commands, deviceId);
  void goToPolicies() => _push(AppRoutes.policies, deviceId);
}
