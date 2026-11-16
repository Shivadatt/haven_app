import 'package:get/get.dart';

import '../controllers/child_usage_controller.dart';
import '../data/child_usage_repository.dart';

/// Dependency injection bindings for the Child Usage feature.
///
/// Registers [ChildUsageRepository] and [ChildUsageController] within
/// the GetX dependency hierarchy while preventing duplicate registrations.
final class ChildUsageBindings extends Bindings {
  ChildUsageBindings({
    this.repository,
  });

  final ChildUsageRepository? repository;

  @override
  void dependencies() {
    final ChildUsageRepository repo = repository ??
        (Get.isRegistered<ChildUsageRepository>()
            ? Get.find<ChildUsageRepository>()
            : ChildUsageRepositoryImpl());

    if (!Get.isRegistered<ChildUsageRepository>()) {
      Get.put<ChildUsageRepository>(repo);
    }

    if (!Get.isRegistered<ChildUsageController>()) {
      Get.put<ChildUsageController>(
        ChildUsageController(repository: repo),
      );
    }
  }
}
