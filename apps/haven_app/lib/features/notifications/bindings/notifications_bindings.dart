import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';

import '../../child_devices/bindings/child_devices_bindings.dart';
import '../../family/data/family_scope.dart';
import '../controllers/notifications_controller.dart';
import '../data/alerts_repository.dart';
import '../data/local_alerts_repository.dart';
import '../services/alert_delivery.dart';

/// DI for the reports screen.
///
/// The device lane comes from the devices feature as a provider, because naming
/// the device a report points at is that feature's answer — F6 — and this screen
/// repeats it rather than restating the evidence and drifting from it.
abstract final class NotificationsDependencies {
  static AlertsRepository ensureRepository() {
    if (!Get.isRegistered<AlertsRepository>()) {
      final FamilyScopeReader scope = FamilyScopeReader(
        auth: () => HavenBackend.auth,
        rows: () => HavenBackend.rows,
      );
      Get.put<AlertsRepository>(
        OfflineHavenBackend.isActive
            ? LocalAlertsRepository.live()
            : HavenAlertsRepository(
                scope: () => scope,
                rows: () => HavenBackend.rows,
                devices: ChildDevicesDependencies.ensureRepository,
              ),
        permanent: true,
      );
    }
    return Get.find<AlertsRepository>();
  }

  static AlertDelivery ensureDelivery() {
    if (!Get.isRegistered<AlertDelivery>()) {
      Get.put<AlertDelivery>(
        const UnregisteredAlertDelivery(),
        permanent: true,
      );
    }
    return Get.find<AlertDelivery>();
  }
}

/// The route takes no argument (`00-app-contract.md:167`): reports belong to the
/// family the signed-in account is in, which the scope reader resolves.
final class NotificationsBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<NotificationsController>(
      NotificationsController(
        repository: NotificationsDependencies.ensureRepository(),
        delivery: NotificationsDependencies.ensureDelivery(),
        feed: () => HavenBackend.feed,
      ),
    );
  }
}
