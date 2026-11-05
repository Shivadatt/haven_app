import 'package:get/get.dart';
import 'package:haven_models/haven_models.dart';

import '../../child_devices/data/devices_repository.dart';
import '../data/app_catalogue.dart';
import '../data/policies_repository.dart';
import '../data/policy_config.dart';
import '../data/policy_rules.dart';

final class AppLimitsController extends GetxController {
  AppLimitsController({
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

  void setCategory(AppCategory category) {
    selectedCategory.value = category;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  List<AppCatalogueItem> get filteredApps {
    final query = searchQuery.value.trim().toLowerCase();
    final cat = selectedCategory.value;

    final allKnown = <String, AppCatalogueItem>{};
    for (final item in AppCatalogue.catalogue) {
      allKnown[item.packageName] = item;
    }
    for (final pkg in config.value.appLimits.keys) {
      allKnown.putIfAbsent(pkg, () => AppCatalogue.lookup(pkg));
    }

    return allKnown.values.where((item) {
      final matchesCat = (cat == AppCategory.all || item.category == cat);
      final matchesQuery = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.packageName.toLowerCase().contains(query);
      return matchesCat && matchesQuery;
    }).toList();
  }

  int? getLimitFor(String packageName) => config.value.appLimits[packageName];

  bool hasLimit(String packageName) =>
      config.value.appLimits.containsKey(packageName);

  Future<bool> setLimit(String packageName, int minutes) async {
    final err = PolicyRules.validateMinutesLimit(minutes, max: 1440);
    if (err != null) {
      errorMessage.value = err;
      return false;
    }
    final nextLimits = Map<String, int>.from(config.value.appLimits);
    nextLimits[packageName.trim()] = minutes;
    config.value = config.value.copyWith(appLimits: nextLimits);
    return _saveConfig();
  }

  Future<bool> removeLimit(String packageName) async {
    final nextLimits = Map<String, int>.from(config.value.appLimits)
      ..remove(packageName.trim());
    config.value = config.value.copyWith(appLimits: nextLimits);
    return _saveConfig();
  }

  Future<bool> toggleLimit(String packageName, bool enable) async {
    if (enable) {
      return setLimit(packageName, 30);
    } else {
      return removeLimit(packageName);
    }
  }

  Future<bool> _saveConfig() async {
    isSaving.value = true;
    errorMessage.value = null;
    final devId = selectedDeviceId.value.isEmpty ? null : selectedDeviceId.value;
    final res = await _policiesRepo.saveConfig(config.value, deviceId: devId);
    isSaving.value = false;
    if (res.isErr) {
      errorMessage.value = res.failureOrNull?.message ?? 'Failed to save limit.';
      return false;
    }
    return true;
  }
}
