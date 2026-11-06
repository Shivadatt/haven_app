import 'package:get/get.dart';

import '../../../core/permissions/permission_status_source.dart';
import '../controllers/permissions_controller.dart';

/// DI for `/permissions`. The source is permanent and honest by
/// construction: Stage 1 registers the `Unconfigured` one at startup.
final class PermissionsBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<PermissionsController>(
      PermissionsController(source: Get.find<PermissionStatusSource>()),
    );
  }
}
