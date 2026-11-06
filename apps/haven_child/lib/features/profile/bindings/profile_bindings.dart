import 'package:get/get.dart';

import '../../../core/session/child_local_session.dart';
import '../../../core/storage/child_profile_repository.dart';
import '../controllers/profile_controller.dart';

/// DI for the child home screen. The repository and session lanes are
/// permanent — registered when storage opened — so this only composes.
final class ProfileBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<ProfileController>(
      ProfileController(
        profiles: Get.find<ChildProfileRepository>(),
        sessions: Get.find<ChildSessionStore>(),
      ),
    );
  }
}
