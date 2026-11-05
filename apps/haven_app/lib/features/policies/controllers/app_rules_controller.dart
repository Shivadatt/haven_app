import 'package:get/get.dart';
import 'package:haven_models/haven_models.dart';

import '../../../app/routes/app_routes.dart';
import '../../child_devices/data/devices_repository.dart';
import '../data/app_catalogue.dart';
import '../data/policies_repository.dart';
import '../data/policy_config.dart';
import '../data/policy_rules.dart';

final class AppRulesController extends GetxController {
  AppRulesController({
    required PoliciesRepository policiesRepo,
    required DevicesRepository devicesRepo,
    String? initialDeviceId,
  }) : _policiesRepo = policiesRepo,
       _devicesRepo = devicesRepo,
       selectedDeviceId = (initialDeviceId ?? '').obs;

  final PoliciesRepository _policiesRepo;
  final DevicesRepository _devicesRepo;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxnString errorMessage = RxnString();
  final Rx<PolicyConfig> config = PolicyConfig.defaults().obs;
  final RxList<Device> devices = <Device>[].obs;
  final RxString selectedDeviceId;
  final RxInt activeTabIndex = 0.obs; // 0 = Allowed, 1 = Blocked
  final Rx<AppCategory> selectedCategory = AppCategory.all.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    final devResult = await _devicesRepo.pairedDevices();
    if (devResult.isOk) {
      devices.value = devResult.valueOrNull ?? [];
      if (selectedDeviceId.value.isEmpty && devices.isNotEmpty) {
        selectedDeviceId.value = devices.first.id;
      }
    }

    final devId = selectedDeviceId.value.isEmpty ? null : selectedDeviceId.value;
    final cfgResult = await _policiesRepo.loadConfig(deviceId: devId);
    if (cfgResult.isOk) {
      config.value = cfgResult.valueOrNull ?? PolicyConfig.defaults();
    }
    isLoading.value = false;
  }

  Future<void> selectDevice(String deviceId) async {
    if (selectedDeviceId.value == deviceId) return;
    selectedDeviceId.value = deviceId;
    await load();
  }

  void switchTab(int index) => activeTabIndex.value = index;
  void setCategory(AppCategory category) => selectedCategory.value = category;
  void setSearchQuery(String query) => searchQuery.value = query;

  List<String> get currentList => activeTabIndex.value == 0
      ? config.value.allowedApps
      : config.value.blockedApps;

  List<AppCatalogueItem> get filteredApps {
    final query = searchQuery.value.trim().toLowerCase();
    final cat = selectedCategory.value;
    final pkgs = currentList;

    return pkgs
        .map(AppCatalogue.lookup)
        .where((item) {
          final matchesCat = (cat == AppCategory.all || item.category == cat);
          final matchesQuery = query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              item.packageName.toLowerCase().contains(query);
          return matchesCat && matchesQuery;
        })
        .toList();
  }

  Future<bool> setAppRule(String packageName, {required bool isBlocked}) async {
    final err = PolicyRules.validatePackageName(packageName);
    if (err != null) {
      errorMessage.value = err;
      return false;
    }
    final clean = packageName.trim();
    // Prevent duplicates: ensure clean is only in target list
    final allowed = config.value.allowedApps.where((p) => p != clean).toList();
    final blocked = config.value.blockedApps.where((p) => p != clean).toList();

    if (isBlocked) {
      blocked.add(clean);
    } else {
      allowed.add(clean);
    }

    config.value = config.value.copyWith(
      allowedApps: allowed,
      blockedApps: blocked,
    );
    return _saveConfig();
  }

  Future<bool> removeAppRule(String packageName) async {
    final clean = packageName.trim();
    final allowed = config.value.allowedApps.where((p) => p != clean).toList();
    final blocked = config.value.blockedApps.where((p) => p != clean).toList();

    config.value = config.value.copyWith(
      allowedApps: allowed,
      blockedApps: blocked,
    );
    return _saveConfig();
  }

  Future<bool> toggleAppStatus(String packageName) async {
    final isCurrentlyBlocked = config.value.blockedApps.contains(packageName);
    return setAppRule(packageName, isBlocked: !isCurrentlyBlocked);
  }

  void goToAppLimits(String packageName) {
    Get.toNamed(
      AppRoutes.appLimits,
      arguments: <String, dynamic>{
        'deviceId': selectedDeviceId.value,
        'packageName': packageName,
      },
    );
  }

  Future<bool> _saveConfig() async {
    isSaving.value = true;
    errorMessage.value = null;
    final devId = selectedDeviceId.value.isEmpty ? null : selectedDeviceId.value;
    final res = await _policiesRepo.saveConfig(config.value, deviceId: devId);
    isSaving.value = false;
    if (res.isErr) {
      errorMessage.value = res.failureOrNull?.message ?? 'Failed to save rules.';
      return false;
    }
    return true;
  }
}
