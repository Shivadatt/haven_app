import 'package:get/get.dart';
import 'package:haven_api/haven_api.dart';

import '../../child_devices/bindings/child_devices_bindings.dart';
import '../../family/data/family_scope.dart';
import '../controllers/session_detail_controller.dart';
import '../controllers/sessions_controller.dart';
import '../data/sessions_repository.dart';
import '../services/media_peer.dart';

/// DI for the two session screens.
///
/// The repository and the peer are permanent: the list and the detail are the
/// same feature read of the same two tables, and the peer holds no state to
/// rebuild per screen. The device lane comes from the devices feature as a
/// provider, because whether a session's device can be named at all is that
/// feature's answer — F6 — and this screen repeats it rather than restating it.
abstract final class SessionsDependencies {
  static SessionsRepository ensureRepository() {
    if (!Get.isRegistered<SessionsRepository>()) {
      final FamilyScopeReader scope = FamilyScopeReader(
        auth: () => HavenBackend.auth,
        rows: () => HavenBackend.rows,
      );
      Get.put<SessionsRepository>(
        HavenSessionsRepository(
          scope: () => scope,
          rows: () => HavenBackend.rows,
          devices: ChildDevicesDependencies.ensureRepository,
        ),
        permanent: true,
      );
    }
    return Get.find<SessionsRepository>();
  }

  static SessionMediaPeer ensurePeer() {
    if (!Get.isRegistered<SessionMediaPeer>()) {
      Get.put<SessionMediaPeer>(const UnspecifiedMediaPeer(), permanent: true);
    }
    return Get.find<SessionMediaPeer>();
  }
}

final class SessionsBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<SessionsController>(
      SessionsController(
        repository: SessionsDependencies.ensureRepository(),
        feed: () => HavenBackend.feed,
      ),
    );
  }
}

/// The contract gives this route a session id (`00-app-contract.md:166`), and
/// only a `String` is read from it.
final class SessionDetailBindings extends Bindings {
  @override
  void dependencies() {
    final Object? arg = Get.arguments;
    Get.put<SessionDetailController>(
      SessionDetailController(
        repository: SessionsDependencies.ensureRepository(),
        peer: SessionsDependencies.ensurePeer(),
        sessionId: arg is String ? arg : '',
        feed: () => HavenBackend.feed,
      ),
    );
  }
}
