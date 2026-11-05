import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../app/routes/app_routes.dart';
import '../data/device_route_args.dart';
import '../data/devices_repository.dart';

/// The device list.
final class DevicesController extends GetxController {
  DevicesController({
    required DevicesRepository repository,
    void Function(String route, Object? arg)? push,
  }) : _repository = repository,
        _push =
           push ??
           ((String route, Object? arg) => Get.toNamed(route, arguments: arg));

  final DevicesRepository _repository;
  final void Function(String route, Object? arg) _push;

  final RxBool isLoading = true.obs;
  final Rx<Result<List<Device>>?> devices = Rx<Result<List<Device>>?>(null);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<List<Device>> read = await _repository.pairedDevices();
    if (isClosed) return;
    devices.value = read;
    isLoading.value = false;
  }

  Future<void> reload() async {
    final Result<List<Device>> read = await _repository.pairedDevices();
    if (isClosed) return;
    devices.value = read;
  }

  Future<Result<Device>> addDevice({
    required String displayName,
    required String childUserId,
    String platform = 'android',
    int? batteryLevel,
  }) async {
    final Result<Device> created = await _repository.createDevice(
      displayName: displayName,
      childUserId: childUserId,
      platform: platform,
      batteryLevel: batteryLevel,
    );
    if (created.isOk) {
      await reload();
    }
    return created;
  }

  void goToDevice(String deviceId) =>
      _push(AppRoutes.deviceDetail, DeviceRouteArgs(deviceId: deviceId));

  /// Pairing is the only way a device gets onto this list in cloud mode.
  void goToPairing() => _push(AppRoutes.pairing, null);
}
