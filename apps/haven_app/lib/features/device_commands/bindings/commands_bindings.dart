import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';

import '../../child_devices/bindings/child_devices_bindings.dart';
import '../../family/data/family_scope.dart';
import '../controllers/commands_controller.dart';
import '../data/commands_repository.dart';

/// DI for the instructions screen.
///
/// The device lane is supplied as a provider because naming the device an
/// instruction was addressed to needs `devices`, and whether that read answers or
/// refuses is the device feature's answer — this screen repeats it rather than
/// paraphrasing the evidence and drifting from it.
abstract final class CommandsDependencies {
  static CommandsRepository ensureRepository() {
    if (!Get.isRegistered<CommandsRepository>()) {
      final FamilyScopeReader scope = FamilyScopeReader(
        auth: () => HavenBackend.auth,
        rows: () => HavenBackend.rows,
      );
      Get.put<CommandsRepository>(
        HavenCommandsRepository(
          scope: () => scope,
          rows: () => HavenBackend.rows,
          devices: ChildDevicesDependencies.ensureRepository,
        ),
        permanent: true,
      );
    }
    return Get.find<CommandsRepository>();
  }
}

final class CommandsBindings extends Bindings {
  @override
  void dependencies() {
    // The contract gives this route a device id (`00-app-contract.md:160`).
    final Object? arg = Get.arguments;
    Get.put<CommandsController>(
      CommandsController(
        repository: CommandsDependencies.ensureRepository(),
        deviceId: arg is String ? arg : '',
      ),
    );
  }
}
