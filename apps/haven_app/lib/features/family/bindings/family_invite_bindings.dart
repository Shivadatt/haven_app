import 'package:get/get.dart';

import '../controllers/family_invite_controller.dart';

/// Dependency injection for the family invite screen.
final class FamilyInviteBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FamilyInviteController>(
      () => FamilyInviteController(),
    );
  }
}
