import 'package:get/get.dart';

import '../../../core/device/device_information.dart';
import '../controllers/device_info_controller.dart';

/// DI for `/device`.
final class DeviceBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<DeviceInfoController>(
      DeviceInfoController(device: Get.find<DeviceInformation>()),
    );
  }
}
