import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';

import '../../family/data/family_scope.dart';
import '../controllers/zone_create_controller.dart';
import '../controllers/zone_editor_controller.dart';
import '../controllers/zones_controller.dart';
import '../data/local_zones_repository.dart';
import '../data/zones_repository.dart';

/// DI for the safe-place screens.
///
/// The write lane is a provider for the same reason the read lane is: the client
/// is installed after the first binding runs. Nothing here decides which writes
/// are possible — the repository states that from the captured grants, and this
/// build's answer is that `safe_zones` has an INSERT policy with no INSERT grant,
/// so the list page shows the refusal where an add button would otherwise be.
abstract final class SafeZonesDependencies {
  static SafeZonesRepository ensureRepository() {
    if (!Get.isRegistered<SafeZonesRepository>()) {
      final FamilyScopeReader scope = FamilyScopeReader(
        auth: () => HavenBackend.auth,
        rows: () => HavenBackend.rows,
      );
      Get.put<SafeZonesRepository>(
        OfflineHavenBackend.isActive
            ? LocalSafeZonesRepository.live()
            : HavenSafeZonesRepository(
              scope: () => scope,
              rows: () => HavenBackend.rows,
              writer: () => HavenBackend.writer,
            ),
        permanent: true,
      );
    }
    return Get.find<SafeZonesRepository>();
  }
}

final class SafeZonesBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<SafeZonesController>(
      SafeZonesController(repository: SafeZonesDependencies.ensureRepository()),
    );
  }
}

/// The editor route carries the id of the one place being changed.
///
/// An argument of the wrong shape becomes an empty id, which the controller reads
/// as "no place was named" instead of querying for every zone in the family.
final class ZoneEditorBindings extends Bindings {
  @override
  void dependencies() {
    final Object? arg = Get.arguments;
    Get.put<SafeZoneEditorController>(
      SafeZoneEditorController(
        zoneId: arg is String ? arg : '',
        repository: SafeZonesDependencies.ensureRepository(),
      ),
    );
  }
}

final class ZoneCreateBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<SafeZoneCreateController>(
      SafeZoneCreateController(
        repository: SafeZonesDependencies.ensureRepository(),
      ),
    );
  }
}
