import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../core/storage/child_local_state.dart';
import '../controllers/registration_controller.dart';
import '../data/blocked_registration_service.dart';
import '../data/child_registration_service.dart';
import '../data/demo_registration_policy.dart';
import '../data/demo_registration_service.dart';
import '../data/registration_repository.dart';

/// Which registration lane a caller wants.
enum RegistrationLane {
  /// The default: every cross-device method answers `blocked(...)` (D-5).
  blocked,

  /// Local-only, deterministic, labelled DEMO in every user-visible string.
  demo,
}

/// DI for the registration contract.
///
/// Stage 2 adds no route, so nothing in `ChildPages` calls this binding yet —
/// it is the seam a Stage-3 route (or a test) uses, and it exists so the
/// BLOCKED lane is the default the app gets when nobody chooses. The lane label
/// is carried by the service, not by a screen's copy.
final class RegistrationBindings extends Bindings {
  RegistrationBindings({
    this.lane = RegistrationLane.blocked,
    this.localState,
    this.clock,
    this.policy = const DemoRegistrationPolicy(),
    this.localIdMinter,
  });

  final RegistrationLane lane;

  /// The child's existing storage lane (`childLocalState` inside
  /// `haven_local.json`). With `null` the DEMO stays purely in-memory.
  final ChildLocalStateStore? localState;
  final Clock? clock;
  final DemoRegistrationPolicy policy;
  final String Function()? localIdMinter;

  @override
  void dependencies() {
    final ChildRegistrationService service = createService();
    Get.put<ChildRegistrationService>(service);
    Get.put<RegistrationController>(RegistrationController(service: service));
  }

  /// The one place that decides which lane is live, so a test can build the
  /// same object graph without a route.
  ChildRegistrationService createService() => switch (lane) {
    RegistrationLane.blocked => BlockedRegistrationService(
      clock: clock ?? systemClock,
    ),
    RegistrationLane.demo => DemoRegistrationService(
      clock: clock ?? systemClock,
      policy: policy,
      persistence: persistence(),
      localIdMinter: localIdMinter,
    ),
  };

  RegistrationRepository? persistence() {
    final ChildLocalStateStore? state = localState;
    return state == null
        ? null
        : LocalRegistrationRepository(state, clock: clock ?? systemClock);
  }
}
