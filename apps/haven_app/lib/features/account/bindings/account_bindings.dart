import 'package:get/get.dart';

import '../controllers/account_controller.dart';
import '../data/account_repository.dart';

/// DI for the account screen.
abstract final class AccountDependencies {
  static AccountRepository ensureRepository() {
    if (!Get.isRegistered<AccountRepository>()) {
      Get.put<AccountRepository>(
        HavenAccountRepository.live(),
        permanent: true,
      );
    }
    return Get.find<AccountRepository>();
  }
}

final class AccountBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<AccountController>(
      AccountController(repository: AccountDependencies.ensureRepository()),
    );
  }
}
