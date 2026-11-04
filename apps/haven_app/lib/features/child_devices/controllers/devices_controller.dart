import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../../../app/routes/app_routes.dart';
import '../data/devices_repository.dart';

/// The device list.
///
/// The read is attempted rather than assumed: the repository answers with the
/// reason the table is unreachable, and this controller hands that straight to
/// the screen. Nothing here falls back to an empty list, because an empty list
/// would tell a parent that nothing is paired when the truth is that Haven
/// cannot see the shelf.
final class DevicesController extends GetxController {
  DevicesController({
    required this._repository,
    void Function(String route, Object? arg)? push,
  }) : _push =
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

  @override
  Future<void> refresh() async {
    devices.value = await _repository.pairedDevices();
  }

  /// Pairing is the only way a device gets onto this list, and that screen does
  /// have something real to show, so the button goes there.
  void goToPairing() => _push(AppRoutes.pairing, null);
}
