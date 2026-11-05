import 'package:get/get.dart';
import '../controllers/app_approvals_controller.dart';
import '../controllers/extension_requests_controller.dart';
import '../data/approvals_repository.dart';
import '../data/local_approvals_repository.dart';

abstract final class ApprovalsDependencies {
  static ApprovalsRepository ensureRepository() {
    if (!Get.isRegistered<ApprovalsRepository>()) {
      Get.put<ApprovalsRepository>(
        LocalApprovalsRepository(),
        permanent: true,
      );
    }
    return Get.find<ApprovalsRepository>();
  }
}

final class AppApprovalsBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppApprovalsController>(
      () => AppApprovalsController(
        repository: ApprovalsDependencies.ensureRepository(),
      ),
    );
  }
}

final class ExtensionRequestsBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExtensionRequestsController>(
      () => ExtensionRequestsController(
        repository: ApprovalsDependencies.ensureRepository(),
      ),
    );
  }
}
