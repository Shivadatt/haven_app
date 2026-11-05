import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';

import '../../child_devices/bindings/child_devices_bindings.dart';
import '../../family/data/family_scope.dart';
import '../controllers/telemetry_controller.dart';
import '../data/telemetry_repository.dart';

/// DI for the telemetry read.
///
/// Telemetry has no page of its own, so there is no `Bindings` subclass here: the
/// device screen calls these two methods when it builds. Keeping the repository
/// registered means the refusal sentences stay owned by the data layer instead of
/// being re-typed by a widget.
abstract final class TelemetryDependencies {
  static TelemetryRepository ensureRepository() {
    if (!Get.isRegistered<TelemetryRepository>()) {
      final FamilyScopeReader scope = FamilyScopeReader(
        auth: () => HavenBackend.auth,
        rows: () => HavenBackend.rows,
      );
      Get.put<TelemetryRepository>(
        HavenTelemetryRepository(
          scope: () => scope,
          rows: () => HavenBackend.rows,
          devices: ChildDevicesDependencies.ensureRepository,
        ),
        permanent: true,
      );
    }
    return Get.find<TelemetryRepository>();
  }

  /// The card's controller, scoped to the device the screen was opened for.
  static TelemetryController ensureController(String deviceId) {
    final String? tag = deviceId.isEmpty ? null : deviceId;
    if (!Get.isRegistered<TelemetryController>(tag: tag)) {
      Get.put<TelemetryController>(
        TelemetryController(repository: ensureRepository(), deviceId: deviceId),
        tag: tag,
      );
    }
    return Get.find<TelemetryController>(tag: tag);
  }
}
