import 'package:get/get.dart';

import '../../child_devices/bindings/child_devices_bindings.dart';
import '../controllers/app_limits_controller.dart';
import 'policies_bindings.dart';

final class AppLimitsBindings extends Bindings {
  @override
  void dependencies() {
    String? deviceId;
    final args = Get.arguments;
    if (args is String) {
      deviceId = args;
    } else if (args is Map) {
      deviceId = args['deviceId'] as String?;
    }

    Get.put<AppLimitsController>(
      AppLimitsController(
        policiesRepo: PoliciesDependencies.ensureRepository(),
        devicesRepo: ChildDevicesDependencies.ensureRepository(),
        initialDeviceId: deviceId,
      ),
    );
  }
}
