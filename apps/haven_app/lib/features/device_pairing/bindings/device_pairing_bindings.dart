import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';

import '../../family/bindings/family_bindings.dart';
import '../../family/data/family_scope.dart';
import '../controllers/pairing_code_controller.dart';
import '../controllers/pairing_controller.dart';
import '../controllers/pairing_simulation_controller.dart';
import '../data/local_pairing_repository.dart';
import '../data/pairing_repository.dart';
import '../data/pairing_simulation_service.dart';

/// DI for the pairing screens.
///
/// The scope reader is built once with the repository so that both halves of a
/// read — "which family am I in" and "what has been requested" — resolve against
/// the same session, and a stale token cannot pair into a family it does not
/// belong to.
abstract final class PairingDependencies {
  static PairingRepository ensureRepository() {
    if (!Get.isRegistered<PairingRepository>()) {
      final FamilyScopeReader scope = FamilyScopeReader(
        auth: () => HavenBackend.auth,
        rows: () => HavenBackend.rows,
      );
      Get.put<PairingRepository>(
        OfflineHavenBackend.isActive
            ? LocalPairingRepository.live(
              family: FamilyDependencies.ensureRepository,
            )
            : HavenPairingRepository(
              scope: () => scope,
              rows: () => HavenBackend.rows,
              family: FamilyDependencies.ensureRepository,
            ),
        permanent: true,
      );
    }
    return Get.find<PairingRepository>();
  }

  static PairingSimulationService ensureSimulationService() {
    if (!Get.isRegistered<PairingSimulationService>()) {
      final FamilyScopeReader scope = FamilyScopeReader(
        auth: () => HavenBackend.auth,
        rows: () => HavenBackend.rows,
      );
      Get.put<PairingSimulationService>(
        PairingSimulationService(
          scope: () => scope,
          writer: () => HavenBackend.writer,
        ),
        permanent: true,
      );
    }
    return Get.find<PairingSimulationService>();
  }
}

final class PairingBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<PairingController>(
      PairingController(repository: PairingDependencies.ensureRepository()),
    );
  }
}

/// The code screen takes the family it was opened for from the route argument,
/// and re-reads it rather than trusting it.
final class PairingCodeBindings extends Bindings {
  @override
  void dependencies() {
    final Object? arg = Get.arguments;
    Get.put<PairingCodeController>(
      PairingCodeController(
        familyId: arg is String ? arg : '',
        repository: PairingDependencies.ensureRepository(),
      ),
    );
  }
}

final class PairingSimulationBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<PairingSimulationController>(
      PairingSimulationController(
        service: PairingDependencies.ensureSimulationService(),
        family: FamilyDependencies.ensureRepository(),
      ),
    );
  }
}
