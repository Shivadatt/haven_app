import 'package:get/get.dart';

import '../controllers/schedules_editor_controller.dart';
import 'policies_bindings.dart';

/// Bindings for the Advanced Schedule Editor route (/policies/schedules).
final class SchedulesEditorBindings extends Bindings {
  @override
  void dependencies() {
    final Object? arg = Get.arguments;
    Get.lazyPut<SchedulesEditorController>(
      () => SchedulesEditorController(
        repository: PoliciesDependencies.ensureRepository(),
        deviceId: arg is String ? arg : '',
      ),
    );
  }
}
